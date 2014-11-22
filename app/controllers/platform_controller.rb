class PlatformController < ApplicationController
  require "net/http"
  require "rexml/document"
  include REXML
  include Favorites

  before_action :set_platform, except: [:retrieve_favorites]

  # Show the logical reporting using the Atmos REST Management API
  def logical_view
    path = "/sysmgmt/tenants/#{@platform.tenant_name}/subtenants"
    @response, temp, temp = atmos_management_request("Get", Hash.new,  path, nil, "tenantadmin")
    path = "/sysmgmt/tenants/#{@platform.tenant_name}/scMetrics"
    @response_metrics, temp, temp = atmos_management_request("Get", Hash.new,  path, nil, "tenantadmin")
    respond_to do |format|
      format.html { render :logical_view }
    end
  end

  # Show the physical reporting using the Atmos REST Management API
  def physical_view
    path = "/sysmgmt/rmgs"
    response_rmgs, temp = atmos_management_request("Get", Hash.new,  path, nil, "sysadmin")
    rmgs = Array.new
    rmgs_hash = Hash.from_xml(response_rmgs.body)
    if rmgs_hash["rmgList"]["rmg"].instance_of? Array
      rmgs_hash["rmgList"]["rmg"].each do |elem|
        rmgs << elem["name"][0]
      end
    elsif rmgs_hash["rmgList"]["rmg"].instance_of? Hash
      rmgs << rmgs_hash["rmgList"]["rmg"]["name"][0]
    end
    nodes = Hash.new
    rmgs.each do |rmg|
      path = "/sysmgmt/rmgs/#{rmg}/nodes"
      response_nodes, temp = atmos_management_request("Get", Hash.new,  path, nil, "sysadmin")
      nodes[rmg] = Array.new
      nodes_hash = Hash.from_xml(response_nodes.body)
      nodes_hash["nodeList"]["node"].each do |elem|
       nodes[rmg] << elem["name"]
      end
    end
    uuids = Hash.new
    nodes.each do |rmg, values|
      uuids[rmg] = Hash.new
      values.each do |node|
        path = "/util/translate?scope=Node&input=name&value=#{node}&output=uuid"
        response_translate, temp = atmos_management_request("Get", Hash.new,  path, nil, "tenantadmin")
        uuids[rmg][node] = Hash.from_xml(response_translate.body)["translated_id"]
      end
    end
    @fs = Hash.new
    nodes.each do |rmg, values|
      @fs[rmg] = Hash.new
      values.each do |node|
        path = "/mgmt/disk_information_for_grid?node_uuid=#{uuids[rmg][node]}"
        response_fs, temp = atmos_management_request("Get", Hash.new,  path, nil, "tenantadmin")
        @fs[rmg][node] = Hash.new
        @temp = ActiveSupport::JSON.decode(response_fs.body)
        ActiveSupport::JSON.decode(response_fs.body)["aaData"].each do |disk|
          @fs[rmg][node][disk[0]] = Hash.new
          @fs[rmg][node][disk[0]]["device_path"] = disk[11]
          @fs[rmg][node][disk[0]]["dae"] = disk[1]
          @fs[rmg][node][disk[0]]["slot_id"] = disk[2]
          @fs[rmg][node][disk[0]]["free_capacity"] = disk[3]
          @fs[rmg][node][disk[0]]["percent_used"] = disk[5]
          @fs[rmg][node][disk[0]]["used_capacity"] = human_size_to_number(disk[6]).to_s
          @fs[rmg][node][disk[0]]["total_capacity"] = human_size_to_number(disk[7]).to_s
          @fs[rmg][node][disk[0]]["make"] = disk[8]
          @fs[rmg][node][disk[0]]["model"] = disk[9]
          @fs[rmg][node][disk[0]]["serial_number"] = disk[10]
          @fs[rmg][node][disk[0]]["atmos_services"] = disk[18]
          @fs[rmg][node][disk[0]]["current_status"] = disk[19]
        end
      end
    end

    respond_to do |format|
      format.html { render :physical_view }
    end
  end

  # Show the subtenant reporting using the Atmos REST Management API
  def show_subtenant_details
    path = "/sysmgmt/tenants/#{@platform.tenant_name}/subtenants/#{params[:subtenant_name]}"
    @response, temp = atmos_management_request("Get", Hash.new,  path, nil, "tenantadmin")
    path = "/sysmgmt/tenants/#{@platform.tenant_name}/#{params[:subtenant_name]}/scMetrics"
    @response_metrics, temp = atmos_management_request("Get", Hash.new,  path, nil, "tenantadmin")
    respond_to do |format|
      format.html { render :show_subtenant_details }
    end
  end

  # Show the uid reporting using the Atmos REST Management API
  def show_uid_metrics
    path = "/sysmgmt/tenants/#{@platform.tenant_name}/#{params[:subtenant_name]}/#{params[:uid]}/scMetrics"
    @response, temp = atmos_management_request("Get", Hash.new,  path, nil, "tenantadmin")
    respond_to do |format|
      format.html { render :show_uid_metrics }
    end
  end

  # Show the form to execute HTTP request
  def manual_request
    if @platform.platform_type == "Atmos"
      @path = "ex: /sysmgmt/rmgs"
      @headers = "One on each line. ex: {'x-atmos-subtenantname' => 't1subtenant'}. The headers needed for authentication will be added automatically for both POX and REST API"
    elsif @platform.platform_type == "Avamar"
        @path = "ex: /rest-api/versions"
        @headers = "One on each line. ex: {'key' => 'value'}. X-Concerto-Authorization will be added automatically"
    elsif @platform.platform_type == "ViPR"
      @path = "ex: /tenant"
      @headers = "One on each line. ex: {'key' => 'value'}. x-sds-auth-token will be added automatically"
    elsif @platform.platform_type == "vCloud Director"
      @path = "ex: /api/org"
      @headers = "One on each line. ex: {'key' => 'value'}. x-vcloud-authorization and Accept will be added automatically"
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
      if @platform.platform_type == "Atmos"
        headers_to_send = Hash.new
        headers.split("\n").each do |row|
          hash = eval(row)
          headers_to_send[hash.keys.first] = Array.new << hash.values.first.to_s
        end
        @response, @headers, @url = atmos_management_request(http_method, headers_to_send, path, body, params[:privilege].downcase)
      elsif @platform.platform_type == "Avamar"
        @response, @headers, @url = avamar_request(http_method, path, headers, body)
      elsif @platform.platform_type == "ViPR"
        @response, @headers, @url = vipr_request(http_method, path, headers, body)
      elsif @platform.platform_type == "vCloud Director"
        @response, @headers, @url = vcloud_request(http_method, path, headers, body)
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
    if @platform.platform_type == "Atmos"
      @path = "ex: /tenant_admin/list_sub_tenant"
      @headers = "One on each line. ex: {'x-atmos-subtenantname' => 't1subtenant'}. The headers needed for authentication will be added automatically for both POX and REST API"
    elsif @platform.platform_type == "ViPR"
      @path = "ex: /tenant"
      @headers = "One on each line. ex: {'key' => 'value'}. x-sds-auth-token will be added automatically"
    elsif @platform.platform_type == "vCloud Director"
      @path = "ex: /api/org"
      @headers = "One on each line. ex: {'key' => 'value'}. x-vcloud-authorization and Accept will be added automatically"
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
      http_method = data["http_method"]
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
        if @platform.platform_type == "Atmos"
          headers_to_send = Hash.new
          headers.split("\n").each do |row|
            hash = eval(row)
            headers_to_send[hash.keys.first] = Array.new << hash.values.first.to_s
          end
          @responses[line], @headers[line], @all_urls[line] = atmos_management_request(http_method, headers_to_send, path, body, data["privilege"].downcase)
        elsif @platform.platform_type == "Avamar"
          @responses[line], @headers[line], @all_urls[line] = avamar_request(http_method, path, headers, body)
        elsif @platform.platform_type == "ViPR"
          @responses[line], @headers[line], @all_urls[line] = vipr_request(http_method, path, headers, body)
        elsif @platform.platform_type == "vCloud Director"
          @responses[line], @headers[line], @all_urls[line] = vcloud_request(http_method, path, headers, body)
        end
      }
    rescue Exception => e
      @exception = e
    end
    respond_to do |format|
      format.js { render 'shared/execute_bulk_requests' }
    end
  end

  # Follow ViPR link returned in the response body
  def follow_link
    data = ActiveSupport::JSON.decode(params[:data])
    http_method = "Get"
    @path = data["path"]
    headers = ""
    body = ""
    begin
      if @platform.platform_type == "ViPR"
        @response, @headers, @url = vipr_request(http_method, @path, headers, body)
      end
    rescue Exception => e
      @exception = e
    end
    respond_to do |format|
      format.js { render :follow_link }
    end
  end

  private

  # Set the current platform API
  def set_platform
    @platform = Platform.find(params[:platform_id])
  end
end
