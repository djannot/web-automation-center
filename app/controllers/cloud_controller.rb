class CloudController < ApplicationController
  require "net/http"
  require "rexml/document"
  require "base64"
  require "hmac-sha1"
  require 'securerandom'
  include REXML
  include Favorites

  before_action :set_cloud, except: [:retrieve_favorites, :about]

  # Show information about this application
  def about
  end

  # Show the form to execute HTTP request
  def manual_request
    if @cloud
      if @cloud.api == "Atmos"
        @path = "ex: /rest/objects/objectid?info"
        @headers = "One on each line. ex: {'x-emc-meta' => 'tag_name1=value1,tag_name2=value2'}. x-emc-date, x-emc-uid and x-emc-signature will be added automatically"
      elsif @cloud.api == "Amazon"
        @path = "ex: /ObjectName"
        @headers = "One on each line. ex: {'Content-MD5' => '033bd94b1168d7e4f0d644c3c95e35bf'}. Date and Authorization will be added automatically"
      elsif @cloud.api == "Swift"
        @path = "ex: /container/ObjectName."
        @headers = "One on each line. ex: {'key' => 'value'}. X-Auth-Token will be added automatically"
      end
    else
      @path = ""
      @headers = "One on each line. ex: {'key' => 'value'}."
      @other = true
    end
    respond_to do |format|
      format.html { render "shared/manual_request" }
    end
  end

  # Execute the HTTP request
  def execute_manual_request
    http_method = params[:http_method]
    path = params[:path]
    headers = params[:headers]
    body = params[:body]
    params.each do |key, value|
      if key.start_with?("replace_") && !key.end_with?("_by")
        path.gsub!("XXX#{value}XXX",params[key + "_by"]) if params[key + "_by"] != ""
        headers.gsub!("XXX#{value}XXX",params[key + "_by"]) if params[key + "_by"] != ""
        body.gsub!("XXX#{value}XXX",params[key + "_by"]) if params[key + "_by"] != ""
      end
    end
    if params[:task_id]
      @task = Task.find(params[:task_id])
      @regexpressions = @task.regexpressions
    end
    begin
      if @cloud
        if @cloud.api == "Atmos"
          @response, @headers, @url = atmos_request(http_method, path, headers, body)
        elsif @cloud.api == "Amazon"
          @response, @headers, @url = amazon_request(http_method, path, headers, body)
        elsif @cloud.api == "Swift"
          @response, @headers, @url = swift_request(http_method, path, headers, body)
        end
      else
        url = path
        uri = URI.parse(url)
        headers_to_send = Hash.new
        headers.split("\n").each do |row|
          hash = eval(row)
          headers_to_send[hash.keys.first.downcase] = hash.values.first.to_s
        end
        if params[:user] != "" && params[:password] != ""
          login = Base64.urlsafe_encode64("#{params[:user]}:#{params[:password]}")
          headers_to_send["Authorization"] = "Basic #{login}"
        end
        @response = http_request(url, uri.port, http_method, headers_to_send, body)
        @headers = headers_to_send
      end
    rescue Exception => e
      @exception = e
    end
    respond_to do |format|
      format.js { render 'shared/execute_manual_request' }
    end
  end

  # Show the form to execute bulk HTTP requests
  def bulk_requests
    if @cloud
      if @cloud.api == "Atmos"
        @path = "ex: /rest/objects/objectid?info"
        @headers = "One on each line. ex: {'x-emc-meta' => 'tag_name1=value1,tag_name2=value2'}. x-emc-date, x-emc-uid and x-emc-signature will be added automatically"
      elsif @cloud.api == "Amazon"
        @path = "ex: /ObjectName"
        @headers = "One on each line. ex: {'Content-MD5' => '033bd94b1168d7e4f0d644c3c95e35bf'}. Date and Authorization will be added automatically"
      elsif @cloud.api == "Swift"
        @path = "ex: /container/ObjectName."
        @headers = "One on each line. ex: {'key' => 'value'}. X-Auth-Token will be added automatically"
      end
    else
      @path = ""
      @headers = "One on each line. ex: {'key' => 'value'}."
    end
    respond_to do |format|
      format.html { render "shared/bulk_requests" }
    end
  end

  # Execute the bulk HTTP requests
  def execute_bulk_requests
    begin
      @responses = Hash.new
      @headers = Hash.new
      @all_urls = Hash.new
      data = ActiveSupport::JSON.decode(params[:data])
      @detailed_results = data["detailed_results"]
      num_threads = data["threads"].to_i
      data["lines_to_send"].threadify(num_threads) { |line|
        path = data["path"].gsub(/XXXCHANGEMEXXX/, line)
        headers = data["headers"].gsub(/XXXCHANGEMEXXX/, line)
        body = data["body"].gsub(/XXXCHANGEMEXXX/, line)
        data.each do |key, value|
          if key.start_with?("replace_") && !key.end_with?("_by")
            path.gsub!("XXX#{value}XXX",data[key + "_by"]) if data[key + "_by"] != ""
            headers.gsub!("XXX#{value}XXX",data[key + "_by"]) if data[key + "_by"] != ""
            body.gsub!("XXX#{value}XXX",data[key + "_by"]) if data[key + "_by"] != ""
          end
        end
        if @cloud
          if @cloud.api == "Atmos"
            @responses[line], @headers[line], @all_urls[line] = atmos_request(data["http_method"], path, headers, body)
          elsif @cloud.api == "Amazon"
            @responses[line], @headers[line], @all_urls[line] = amazon_request(data["http_method"], path, headers, body)
          elsif @cloud.api == "Swift"
            @responses[line], @headers[line], @all_urls[line] = swift_request(data["http_method"], path, headers, body)
          end
        else
          url = path
          uri = URI.parse(url)
          headers_to_send = Hash.new
          headers.split("\n").each do |row|
            hash = eval(row)
            headers_to_send[hash.keys.first.downcase] = hash.values.first.to_s
          end
          @responses[line] = http_request(url, uri.port, data["http_method"], headers_to_send, body)
          @headers[line] = headers_to_send
        end
      }
    rescue Exception => e
      @exception = e
    end
    respond_to do |format|
      format.js { render 'shared/execute_bulk_requests' }
    end
  end

  # Show how to use the Amazon S3 multipart upload feature
  def multipart_upload
  end

  # Execute the Amazon S3 multipart upload
  def execute_multipart_upload
    begin
      filename = params[:file].original_filename
      @path = "/#{filename}"
      file_size = params[:file].size
      five_megabytes = 5 * 1024 * 1024
      @url_parts = Hash.new
      @responses_parts = Hash.new
      @headers_parts = Hash.new
      @response_init_upload, @headers_init_upload, @url_init_upload = amazon_request("Post", "/#{filename}?uploads", "", "")
      logger.info(@response_init_upload.inspect.to_s)
      if @response_init_upload.status == 200
        response_init_upload_hash = Hash.from_xml(@response_init_upload.body)
        upload_id = response_init_upload_hash["InitiateMultipartUploadResult"]["UploadId"]
        num_parts = (file_size.to_f / five_megabytes.to_f).ceil
        num_threads = params[:threads].to_i
        file = params[:file].open
        (1..num_parts).to_a.threadify(num_threads) { |thread|
          chunk = thread == num_parts ? file_size - ((num_parts - 1) * five_megabytes) : five_megabytes
          @responses_parts[thread], @headers_parts[thread], @url_parts[thread] = amazon_request("Put", "/#{filename}?partNumber=#{thread}&uploadId=#{upload_id}", "", file.read(chunk))
        }
        file.close
        @body = "<CompleteMultipartUpload>"
          (1..num_parts).to_a.each { |part_number|
            logger.info(@responses_parts[part_number].inspect)
            etag = @responses_parts[part_number].get_header("ETag").gsub(/^"|"$/, '')
            @body += "<Part>"
            @body += "<PartNumber>#{part_number}</PartNumber>"
            @body += "<ETag>#{etag}</ETag>"
            @body += "</Part>"
          }
        @body += "</CompleteMultipartUpload>"
        @response, @headers, @url_completing = amazon_request("Post", "/#{filename}?uploadId=#{upload_id}", "", @body)
      else
        @exception = "Can't initiate multipart upload. Status = #{@response_init_upload.status}"
      end
      logger.info(@response_init_upload.status.to_s)
    rescue Exception => e
      @exception = e
    end
    respond_to do |format|
      format.html { render :execute_multipart_upload }
    end
  end

  # Show how to use the Amazon S3 multipart upload feature from the web browser
  def client_side_multipart_upload
  end

  # Execute the Amazon S3 multipart upload from the web browser
  def execute_client_side_multipart_upload
    begin
      @headers = Hash.new
      @file_size = params["file_size"].to_i
      five_megabytes = 5 * 1024 * 1024
      @filename = params[:file_name]
      @num_threads = params[:threads].to_i
      @num_threads = 2 if @num_threads < 2
      @response_init_upload, @headers_init_upload = amazon_request("Post", "/#{@filename}?uploads", "", "")
      @uri = URI.parse(@cloud.url)
      if @response_init_upload.status == 200
        response_init_upload_hash = Hash.from_xml(@response_init_upload.body)
        @upload_id = response_init_upload_hash["InitiateMultipartUploadResult"]["UploadId"]
        @num_parts = (@file_size.to_f / five_megabytes.to_f).ceil
        @authorizations = Hash.new
        @headers = Hash.new
        @ip_addresses = Hash.new
        complete_multipart_upload_xml_size = 51
        (1..@num_parts).to_a.each do |part_number|
          complete_multipart_upload_xml_size += 85
          complete_multipart_upload_xml_size += part_number.to_s.length
          chunk = part_number == @num_parts ? @file_size - ((@num_parts - 1) * five_megabytes) : five_megabytes
          signature, @authorizations[part_number], @headers[part_number], @ip_addresses[part_number] = sign_amazon_request("Put", "/#{@filename}?partNumber=#{part_number}&uploadId=#{@upload_id}", "{'Content-Length' => '#{chunk.to_s}'}\n{'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'}", "", nil)
        end
        signature, @complete_multipart_upload_authorization, @complete_multipart_upload_headers , @complete_multipart_upload_ip_address = sign_amazon_request("Post", "/#{@filename}?uploadId=#{@upload_id}", "{'Content-Length' => '#{complete_multipart_upload_xml_size.to_s}'}\n{'Content-Type' => 'text/xml; charset=UTF-8'}", "", nil)
        @url = request.base_url
        html = render_to_string(:partial => "execute_client_side_multipart_upload")
        key = SecureRandom.uuid
        response, headers = amazon_request("Put", "/#{key}", "{'Content-Type' => 'text/html'}", html)
        logger.info "Key: " + key
        expiration = Time.now.to_i + 360
        signature_url, authorization_url, headers_url, ip_address_url = sign_amazon_request("Get", "/#{key}", "", "", expiration.to_s)
        @shareable_url = @uri.scheme + "://#{@cloud.bucket}.#{@uri.host}:#{@cloud.port}/#{key}?AWSAccessKeyId=#{@cloud.token}&Signature=#{URI.encode_www_form_component signature_url}&Expires=#{expiration}"
      else
        @exception = "Can't initiate multipart upload. Status = #{@response_init_upload.status}"
      end
    rescue Exception => e
      @exception = e
    end
    respond_to do |format|
      format.js { render :execute_client_side_multipart_upload }
    end
  end

  # Hidden feature under development to show how to use the Amazon S3 Post form feature
  def html_post_form
    expiration = (Time.now + 360).utc.strftime("%Y-%m-%dT%H:%M:%SZ")
    policy_document = %{
{"expiration": "#{expiration}",
  "conditions": [
    {"bucket": "#{@cloud.bucket}"},
    ["starts-with", "$key", "TE"],
    {"success_action_redirect": "http://www.google.fr/"},
    ["content-length-range", 0, 1048576]
  ]
}
    }
    @policy = Base64.encode64(policy_document).gsub("\n","")
    @signature = Base64.encode64(
    OpenSSL::HMAC.digest(
        OpenSSL::Digest::Digest.new('sha1'),
        @cloud.shared_secret, @policy)
    ).gsub("\n","")
  end
end
