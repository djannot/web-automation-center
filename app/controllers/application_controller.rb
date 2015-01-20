module Net
   module HTTPHeader
     def capitalize(name) name end
   end
end

module Favorites
  #Create a new favorite item
  def add_favorite
    params[:api_type] = "Other platform" if params[:api_type] == ""
    params[:api] = "Other API" if params[:api] == ""
    @favorite = Favorite.new(params)
    current_user
    @favorite.user_id = current_user.id
    @favorite.save
    respond_to do |format|
      format.js { render 'shared/add_favorite' }
    end
  end

  # Update an existing favorite item
  def update_favorite
    @favorite = Favorite.find(params[:id])
    @favorite.update_attributes(:description => params[:description], :http_method => params[:http_method], :path_or_url => params[:path_or_url], :headers => params[:headers], :body => params[:body])
    @favorite.update_attribute(:privilege, params[:privilege]) if @favorite.privilege
    @updated = false
    if @favorite.save
      @updated = true
    end
    respond_to do |format|
      format.js { render 'shared/update_favorite' }
    end
  end

  # Get the favorite items
  def retrieve_favorites
    current_user
    @demos = @current_user.demos.all
    @cloud = Cloud.find(params[:cloud_id]) if params[:cloud_id] && params[:cloud_id] != "0"
    @platform = Platform.find(params[:platform_id]) if params[:platform_id]
    @favorites = Hash.new
    all_favorites = @current_user.favorites.all
    all_favorites.each do |favorite|
      @favorites[favorite.api_type] = Hash.new unless @favorites.key?(favorite.api_type)
      @favorites[favorite.api_type][favorite.api] = Array.new unless @favorites[favorite.api_type][favorite.api]
      @favorites[favorite.api_type][favorite.api] << favorite
    end
    respond_to do |format|
      format.js { render 'shared/retrieve_favorites' }
    end
  end

  # Replace the HTML fields by the data of the favorite item
  def select_favorite
    @favorite = Favorite.find(params[:id])
    respond_to do |format|
      format.js { render 'shared/select_favorite' }
    end
  end

  # Replace the HTML fields by the data of the favorite item and execute the request
  def execute_favorite
    @favorite = Favorite.find(params[:id])
    respond_to do |format|
      format.js { render 'shared/execute_favorite' }
    end
  end

  # Delete a favorite item
  def delete_favorite
    @favorite = Favorite.find(params[:id])
    @deleted = false
    if Task.where(["favorite_id = ?", @favorite.id]).count == 0
      @favorite.delete
      @deleted = true
    end
    respond_to do |format|
      format.js { render 'shared/delete_favorite' }
    end
  end
end

class ApplicationController < ActionController::Base
  require "rexml/document"
  require 'net/http'
  include REXML
  require 'base64'
  require 'hmac-sha1'

  before_action :require_login, :set_variables
  helper_method :current_user

	private

  # Define the current version of the application and check if the environment variables are set to use Amazon S3 (or another Amazon S3 compliant storage platform) to backup/restore data and share data among users
  def set_variables
    @version = "1.1.0"
    begin
      s3 = Struct.new(:url, :port, :bucket, :token, :shared_secret, :ip_addresses)
      if ENV['S3_ACCESS_KEY_ID'] && ENV['S3_SECRET_ACCESS_KEY'] && ENV['S3_URL'] && ENV['S3_PORT'] && ENV['S3_BUCKET']
        @s3 = s3.new(ENV['S3_URL'], ENV['S3_PORT'].to_i, ENV['S3_BUCKET'], ENV['S3_ACCESS_KEY_ID'], ENV['S3_SECRET_ACCESS_KEY'], "")
      end
    rescue
    end
  end

  # Redirect to login page if user not already loged in
	def require_login
		unless session[:user_id] || User.exists?(:id => session[:user_id])
			redirect_to :controller => "sessions", :action => "new"
		end
	end

  # Get the current user
	def current_user
		if session[:user_id] && User.exists?(:id => session[:user_id])
	  	@current_user ||= User.find(session[:user_id])
	  end
	end

  # If different IP addresses are defined for a specific cloud API, return the different
  # IP addresses (generally used to balance the load among the different IP addresses)
  # @return [Array] IP addresses
  def get_ip_addresses
    ip_addresses = Array.new
    if @cloud.ip_addresses.length > 0
      ip_addresses = eval(@cloud.ip_addresses)
    else
      ip_addresses << URI.parse(@cloud.url).host
    end
    return ip_addresses
  end

  # Set the current cloud API
  def set_cloud
    @cloud = Cloud.find(params[:cloud_id]) unless params[:cloud_id] == "0"
  end

  # Method used to send an HTTP request
  # @param url [String] the target URL
  # @param port [Integer] the target port
  # @param http_method [String] the HTTP method (commonly HEAD, GET, PUT, POST or DELETE)
  # @param headers [Hash] the HTTP headers
  # @param body [String] the body
  # @return [Response] the HTTP response of the request
  def http_request(url, port, http_method, headers, body)
    Excon.defaults[:ssl_verify_peer] = false
    connection = Excon.new(URI.escape(url), :port => port)
    response = connection.request(
                :method => http_method.upcase,
                :headers => headers,
                :body => body
                )
    return response
  end

  # Sign an Atmos REST request
  # @param http_method [String] the HTTP method (commonly HEAD, GET, PUT, POST or DELETE)
  # @param path [String] the target path
  # @param headers [String] the HTTP headers in the format !{'key' => 'value'}\\n!{'key' => 'value'}
  # @param body [String] the body
  # @return [String] the computed signature
  # @return [Hash] the headers (including the signature)
  # @return [String] an IP address retrieved from the list of IP addresses associated with the cloud API
  def sign_atmos_request(http_method, path, headers, body)
    headers_to_send = Hash.new
    headers.split("\n").each do |row|
      hash = eval(row)
      headers_to_send[hash.keys.first.downcase] = hash.values.first.to_s
    end
    date = Time.zone.now.httpdate
    headers_to_send["x-emc-date"] = date
    headers_to_send["x-emc-uid"] = @cloud.token
    if headers_to_send.key?("x-emc-meta") || headers_to_send.key?("x-emc-listable-meta")
      headers_to_send["x-emc-utf8"] = "true"
    end
    canonicalized_emc_headers = ""
    content_type = ""
    headers_to_send.sort.map do |key, value|
      if key.downcase.start_with?("x-emc-")
        canonicalized_emc_headers += key.downcase + ":" + value + "\n"
      end
      content_type = value if key.downcase == "content-type"
    end
    canonicalized_emc_headers.chomp!
    if body.length > 0
      headers_to_send["Content-Length"] = body.bytesize.to_s
    end
    headers_to_send.key?("range") ? range = headers_to_send["range"] : range = ""
    canonicalized_resource = path.split(/\=/)[0].downcase
    string_to_sign = http_method.upcase + "\n" + content_type + "\n" + range + "\n" + "\n" + canonicalized_resource + "\n" + canonicalized_emc_headers
    hmac = HMAC::SHA1.new(Base64.decode64(@cloud.shared_secret))
    hmac.update(string_to_sign)
    signature = Base64.encode64(hmac.digest).chomp
    ip_address = get_ip_addresses.sample
    headers_to_send["x-emc-signature"] = signature
    return signature, headers_to_send, ip_address
  end

  # Execute an Atmos REST request
  # @param http_method [String] the HTTP method (commonly HEAD, GET, PUT, POST or DELETE)
  # @param path [String] the target path
  # @param headers [String] the HTTP headers in the format !{'key' => 'value'}\\n!{'key' => 'value'}
  # @param body [String] the body
  # @return [Response] the HTTP response
  # @return [Hash] the headers sent
  # @return [String] the target URL
  def atmos_request(http_method, path, headers, body)
    signature, headers_to_send, ip_address = sign_atmos_request(http_method, path, headers, body)
    uri = URI.parse(@cloud.url)
    url = uri.scheme + '://' + ip_address + path
    response = http_request(url, @cloud.port, http_method, headers_to_send, body)
    return response, headers_to_send, url
  end

  # Sign an Amazon S3 request
  # @param http_method [String] the HTTP method (commonly HEAD, GET, PUT, POST or DELETE)
  # @param path [String] the target path
  # @param headers [String] the HTTP headers in the format !{'key' => 'value'}\\n!{'key' => 'value'}
  # @param body [String] the body
  # @param expiration [String] the expiration timestamp of the signature
  # @return [String] the computed signature
  # @return [String] the authorization including the computed signature
  # @return [Hash] the headers (including the authorization)
  # @return [String] an IP address retrieved from the list of IP addresses associated with the cloud API
  def sign_amazon_request(http_method, path, headers, body, expiration)
    headers_to_send = Hash.new
    headers.split("\n").each do |row|
      hash = eval(row)
      headers_to_send[hash.keys.first.downcase] = hash.values.first.to_s
    end
    canonicalized_amz_headers = ""
    content_type = ""
    content_md5 = ""
    unless expiration
      expiration = ""
      date = Time.zone.now.httpdate
      headers_to_send["x-amz-date"] = date
    end
    headers_to_send.sort.map do |key, value|
      if key.downcase.start_with?("x-amz-") || key.downcase.start_with?("x-emc-")
        canonicalized_amz_headers += key.downcase + ":" + value + "\n"
      end
      content_type = value if key == "content-type"
      content_md5 = value if key == "content-md5"
    end
    if path.length > 0
      canonicalized_resource = "/" + @cloud.bucket + URI.escape(path.split("?")[0])
    else
      canonicalized_resource = "/" + @cloud.bucket
    end
    query_params_to_keep = ["acl", "lifecycle", "location", "logging", "notification", "partnumber", "policy", "requestpayment", "torrent", "uploadid", "uploads", "versionid", "versioning", "versions", "website", "cors", "delete"]
    query_params = Hash.new
    if path.include?("?")
      path.split("?")[1].split("&").each do |kv|
        if query_params_to_keep.include?(kv.split("=")[0].downcase)
          query_params[kv.split("=")[0]] = kv.split("=")[1]
        end
      end
    end
    if query_params.length > 0
      canonicalized_resource << "?"
      i = 0
      query_params.sort.map do |key, value|
        if i > 0
          canonicalized_resource << "&"
        end
        if value
          canonicalized_resource << key << "=" << value
        else
          canonicalized_resource << key
        end
        i += 1
      end
    end
    string_to_sign = http_method.upcase + "\n" + content_md5 + "\n" + content_type + "\n" + expiration + "\n" + canonicalized_amz_headers + canonicalized_resource
    hmac = HMAC::SHA1.new(@cloud.shared_secret)
    hmac.update(string_to_sign)
    signature = Base64.encode64(hmac.digest).strip
    authorization = "AWS " + @cloud.token + ":" + signature
    headers_to_send["authorization"] = authorization
    ip_address = get_ip_addresses.sample
    begin
      Resolv.getaddress @cloud.bucket + '.' + ip_address
      headers_to_send["host"] = @cloud.bucket + '.' + ip_address
    rescue
      headers_to_send["host"] = ip_address
    end
    return signature, authorization, headers_to_send, ip_address
  end

  # Execute an Amazon S3 request
  # @param http_method [String] the HTTP method (commonly HEAD, GET, PUT, POST or DELETE)
  # @param path [String] the target path
  # @param headers [String] the HTTP headers in the format !{'key' => 'value'}\\n!{'key' => 'value'}
  # @param body [String] the body
  # @param [Hash] options
  #   [:cloud] The cloud API
  # @return [Response] the HTTP response
  # @return [Hash] the headers sent
  # @return [String] the target URL
  def amazon_request(http_method, path, headers, body, *args)
    options = args.extract_options!
    @cloud = options[:cloud] if options[:cloud]
    path[0,0] = '/' unless path.start_with? '/'
    if @cloud.bucket.length == 0
      if path.length > 0
        path.slice!(0,1)
      else
        path = ''
      end
    end
    signature, authorization, headers_to_send, ip_address = sign_amazon_request(http_method, path, headers, body, nil)
    uri = URI.parse(@cloud.url)
    begin
      Resolv.getaddress @cloud.bucket + '.' + ip_address
      url = uri.scheme + '://' + @cloud.bucket + '.' + ip_address + path
    rescue
      url = uri.scheme + '://' + ip_address + '/' + @cloud.bucket + path
    end
    response = http_request(url, @cloud.port, http_method, headers_to_send, body)
    if response.status == 307
      url = response.get_header('location')
      response = http_request(url , @cloud.port, http_method, headers_to_send, body)
    end
    return response, headers_to_send, url
  end

  # Execute a Swift request
  # @param http_method [String] the HTTP method (commonly HEAD, GET, PUT, POST or DELETE)
  # @param path [String] the target path
  # @param headers [String|Hash] the HTTP headers as a Hash or as a String in the format !{'key' => 'value'}\\n!{'key' => 'value'}
  # @param body [String] the body
  # @return [Response] the HTTP response
  # @return [Hash] the headers sent
  # @return [String] the target URL
  def swift_request(http_method, path, headers, body)
    headers_login = Hash.new
    headers_login['X-Auth-User'] = @cloud.token
    headers_login['X-Auth-Key'] = @cloud.shared_secret
    url_login = @cloud.url + "/v1.0"
    uri_login = URI.parse(@cloud.url)
    response_login = http_request(url_login, @cloud.port, "Get", headers_login, "")
    if headers.kind_of?(Hash)
      headers_to_send = headers
    else
      headers_to_send = Hash.new
      headers.split("\n").each do |row|
        hash = eval(row)
        headers_to_send[hash.keys.first] = hash.values.first.to_s
      end
    end
    if body.length > 0
      headers_to_send["Content-Length"] = body.bytesize.to_s
    end
    headers_to_send['X-Auth-Token'] = response_login.headers['X-Auth-Token']
    if @cloud.bucket == ""
      url = response_login.get_header('X-Storage-Url') + path
    else
      url = response_login.get_header('X-Storage-Url') + '/' + @cloud.bucket + path
    end
    response = http_request(url, @cloud.port, http_method, headers_to_send, body)
    return response, headers_to_send, url
  end

  # Execute an Atmos REST Management API request
  # @param http_method [String] the HTTP method (commonly HEAD, GET, PUT, POST or DELETE)
  # @param headers [Hash] the HTTP headers
  # @param path [String] the target path
  # @param body [String] the body
  # @param user [String] the user
  # @return [Response] the HTTP response
  # @return [Hash] the headers sent
  # @return [String] the target URL
  def atmos_management_request(http_method, headers, path, body, user)
    puts "ok"
    url = "https://#{@platform.ip}" + path
    if path.start_with?("/sysmgmt")
      if user == "tenantadmin"
        headers["x-atmos-tenantadmin"] = @platform.tenant_admin
        headers["x-atmos-tenantadminpassword"] = @platform.tenant_admin_password
        headers["x-atmos-authtype"] = "password"
      elsif user == "sysadmin"
        headers["x-atmos-systemadmin"] = @platform.sys_admin
        headers["x-atmos-systemadminpassword"] = @platform.sys_admin_password
        headers["x-atmos-authtype"] = "password"
      end
      response = http_request(url, 443, http_method, headers, body)
    else
      if user == "tenantadmin"
        url_login = "https://#{@platform.ip}/user/verify"
        uri_login = URI.parse(url_login)
        http_login = Net::HTTP.new(uri_login.host, uri_login.port)
        http_login.use_ssl = true
        http_login.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request_login = Net::HTTP::Get.new(uri_login.request_uri)
        request_login.body = "tenant_name=#{@platform.tenant_name}&username=#{@platform.tenant_admin}&password=#{@platform.tenant_admin_password}"
        response_login = http_login.request(request_login)
      elsif user == "sysadmin"
        url_login = "https://#{@platform.ip}/mgmt_login/verify"
        response_login = http_request(url_login, 443, "Get", Hash.new, "auth_type=remote&auth_addr=#{@platform.ip}&username=#{@platform.sys_admin}&password=#{@platform.sys_admin_password}")
      end
      headers['Cookie'] = response_login["Set-Cookie"]
      response = http_request(url, 443, http_method, headers, body)
    end
    return response, headers, url
  end

  # Execute a ViPR REST Management API request
  # @param http_method [String] the HTTP method (commonly HEAD, GET, PUT, POST or DELETE)
  # @param path [String] the target path
  # @param headers [String|Hash] the HTTP headers as a Hash or as a String in the format !{'key' => 'value'}\\n!{'key' => 'value'}
  # @param body [String] the body
  # @return [Response] the HTTP response
  # @return [Hash] the headers sent
  # @return [String] the target URL
  def vipr_request(http_method, path, headers, body)
    if headers.kind_of?(Hash)
      headers_to_send = headers
    else
      headers_to_send = Hash.new
      headers.split("\n").each do |row|
        hash = eval(row)
        headers_to_send[hash.keys.first] = Array.new << hash.values.first.to_s
      end
    end
    headers_to_send.each do |key, value|
      headers_to_send[key] = value[0]
    end
    login = Base64.encode64("#{@platform.sys_admin}:#{@platform.sys_admin_password}").chomp
    url_auth = "https://#{@platform.ip}/login"
    response_auth = http_request(url_auth, 4443, "Get", {'Authorization' => "Basic #{login}"}, "")
    headers_to_send['x-sds-auth-token'] = response_auth.get_header('x-sds-auth-token')
    url = "https://#{@platform.ip}" + path
    port = path.start_with?("/api") ? 443 : 4443
    response = http_request(url, port, http_method, headers_to_send, body)
    return response, headers_to_send, url
  end

  # Execute an Avamar REST Management API request
  # @param http_method [String] the HTTP method (commonly HEAD, GET, PUT, POST or DELETE)
  # @param path [String] the target path
  # @param headers [String|Hash] the HTTP headers as a Hash or as a String in the format !{'key' => 'value'}\\n!{'key' => 'value'}
  # @param body [String] the body
  # @return [Response] the HTTP response
  # @return [Hash] the headers sent
  # @return [String] the target URL
  def avamar_request(http_method, path, headers, body)
    if headers.kind_of?(Hash)
      headers_to_send = headers
    else
      headers_to_send = Hash.new
      headers.split("\n").each do |row|
        hash = eval(row)
        headers_to_send[hash.keys.first] = Array.new << hash.values.first.to_s
      end
    end
    headers_to_send.each do |key, value|
      headers_to_send[key] = value[0]
    end
    login = Base64.urlsafe_encode64("#{@platform.sys_admin}:#{@platform.sys_admin_password}")
    url_auth = "https://#{@platform.ip}/rest-api/login"
    response_auth = http_request(url_auth, 8543, "Post", {'Authorization' => "Basic #{login}"}, "")
    headers_to_send['X-Concerto-Authorization'] = response_auth.get_header('X-Concerto-Authorization')
    url = "https://#{@platform.ip}" + path
    port = 8543
    response = http_request(url, port, http_method, headers_to_send, body)
    return response, headers_to_send, url
  end

  # Execute a VMware vCloud Director REST Management API request
  # @param http_method [String] the HTTP method (commonly HEAD, GET, PUT, POST or DELETE)
  # @param path [String] the target path
  # @param headers [String|Hash] the HTTP headers as a Hash or as a String in the format !{'key' => 'value'}\\n!{'key' => 'value'}
  # @param body [String] the body
  # @return [Response] the HTTP response
  # @return [Hash] the headers sent
  # @return [String] the target URL
  def vcloud_request(http_method, path, headers, body)
    if headers.kind_of?(Hash)
      headers_to_send = headers
    else
      headers_to_send = Hash.new
      headers.split("\n").each do |row|
        hash = eval(row)
        headers_to_send[hash.keys.first] = Array.new << hash.values.first.to_s
      end
    end
    headers_to_send.each do |key, value|
      headers_to_send[key] = value[0]
    end
    response_login_url = http_request("http://#{@platform.ip}/api/versions", 80, "Get", {}, "")
    response_login_url_hash = Hash.from_xml(response_login_url.body)
    login_url = response_login_url_hash["SupportedVersions"]["VersionInfo"].last["LoginUrl"]
    version = response_login_url_hash["SupportedVersions"]["VersionInfo"].last["Version"]
    if @platform.tenant_name.length > 0
      login = Base64.urlsafe_encode64("#{@platform.sys_admin}@#{@platform.tenant_name}:#{@platform.sys_admin_password}")
    else
      login = Base64.urlsafe_encode64("#{@platform.sys_admin}@System:#{@platform.sys_admin_password}")
    end
    response_login = http_request(login_url, 443, "Post", {'Authorization' => "Basic #{login}", 'Accept' => "application/*+xml;version=#{version}" }, "")
    headers_to_send['x-vcloud-authorization'] = response_login.get_header('x-vcloud-authorization')
    headers_to_send['Accept'] = "application/*+xml;version=#{version}"
    url = "https://#{@platform.ip}" + path
    response = http_request(url, 443, http_method, headers_to_send, body)
    return response, headers_to_send, url
  end

  # Conver a value in human size to number
  # @param value [String] the value in format like '10 MB'
  # @return [Float] the size
  def human_size_to_number(value)
    size = value.split[0].to_f
    unit = value.split[1]
    if unit == "KB"
      size = size * 1024
    elsif unit == "MB"
      size = size * 1024 * 1024
    elsif unit == "GB"
      size = size * 1024 * 1024 * 1024
    elsif unit == "TB"
      size = size * 1024 * 1024 * 1024 * 1024
    end
    return size
  end

  require 'pathname'

  Pathname.class_eval do
    def to_str
      to_s
    end
  end
end
