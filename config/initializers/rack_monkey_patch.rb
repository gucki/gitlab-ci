# We have to get this fix in: https://github.com/rack/rack/commit/b0593078ce792a380779528a6a135c066aa03515
# Without this fix, status updates from the runners for builds with huge output are rejected with a 403
# Forbidden because the request cannot be parsed. Hopefully an official release of rack containing this
# fix will be available soon.

require "rack/request"

module Rack
  class Request
    def POST
      if @env["rack.input"].nil?
        raise "Missing rack.input"
      elsif @env["rack.request.form_input"].equal? @env["rack.input"]
        @env["rack.request.form_hash"]
      elsif form_data? || parseable_data?
        unless @env["rack.request.form_hash"] = parse_multipart(env)
          form_vars = @env["rack.input"].read

          # Fix for Safari Ajax postings that always append \0
          # form_vars.sub!(/\0\z/, '') # performance replacement:
          form_vars.slice!(-1) if form_vars[-1] == ?\0

          @env["rack.request.form_vars"] = form_vars
          @env["rack.request.form_hash"] = parse_query(form_vars)

          @env["rack.input"].rewind
        end
        @env["rack.request.form_input"] = @env["rack.input"]
        @env["rack.request.form_hash"]
      else
        {}
      end
    end
  end
end
