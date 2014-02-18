class ScriptsController < ApplicationController
	# we'll selectively activate the scripts layout when appropriate
	layout 'application'

	def index
		@scripts = Script.all.includes(:user)
	end

	def show
		@script = versionned_script(params[:id], params[:version])
		if @script.nil?
			# no good
			render :status => 404
			return
		end
		render :layout => 'scripts'
	end

	def show_code
		@script = Script.find(params[:script_id])
		@code = @script.script_versions.last.code
		render :layout => 'scripts'
	end

	def user_js
		script = Script.find(params[:script_id])
		render :text => script.script_versions.last.code, :content_type => 'text/javascript'
	end

	def install_ping
		Script.record_install(params[:script_id], request.remote_ip)
		render :nothing => true, :status => 204
	end

	def diff
		@script = Script.find(params[:script_id])
		versions = [params[:v1].to_i, params[:v2].to_i]
		@old_version = ScriptVersion.find(versions.min)
		@new_version = ScriptVersion.find(versions.max)
		if @old_version.nil? or @new_version.nil? or @old_version.script_id != @script.id or @new_version.script_id != @script.id
			render :text => 'Invalid versions provided.', :status => 400, :layout => 'scripts'
			return
		end
		@diff = Diffy::Diff.new(@old_version.code, @new_version.code).to_s(:html).html_safe
		render :layout => 'scripts'
	end

private

	def versionned_script(script_id, version_id)
		return nil if script_id.nil?
		script_id = script_id.to_i
		return Script.find(script_id) if version_id.nil?
		version_id = version_id.to_i
		script_version = ScriptVersion.find(version_id)
		return nil if script_version.nil? or script_version.script_id != script_id
		script = Script.new
		script.apply_from_script_version(script_version)
		script.id = script_id
		script.updated_at = script_version.updated_at
		script.user = script_version.script.user
		script.created_at = script_version.created_at
		script.updated_at = script_version.updated_at
		return script
	end

end