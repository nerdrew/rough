require_relative 'rpc_registry'
require_relative 'invalid_request_proto'
require 'action_dispatch'

module Rough

  module BaseController

    PROTO_MIME = Mime::Type.new('application/x-protobuf')

    def self.included(base)
      base.class_eval do
        before_action :log_proto, if: :rpc?
        alias_method :params_without_request_proto, :params
        include Methods
      end
    end

    module Methods
      private

      def params
        if super[:rpc]
          ActionController::Parameters.new(request_proto.to_hash)
        else
          params_without_request_proto
        end
      end

      def render(options = {})
        return if performed?

        if rpc?
          if request.accept == PROTO_MIME || request.content_type == PROTO_MIME
            response.headers['Content-Type'] = PROTO_MIME.to_s
            super plain: response_proto.encode, status: options[:status]
          else
            super json: response_proto.to_json, status: options[:status]
          end
        else
          super
        end
      end

      def request_proto
        return nil unless rpc?

        @request_proto ||=
          if request.content_type == PROTO_MIME
            RpcRegistry.request_class_for(rpc_name).decode(request.body.read)
          else
            RpcRegistry.request_class_for(rpc_name).new(params_without_request_proto.permit!)
          end
      rescue TypeError => e
        raise InvalidRequestProto, e
      end

      def response_proto
        return nil unless rpc?

        @response_proto ||= RpcRegistry.response_class_for(rpc_name).new
      end

      def rpc?
        rpc_name
      end

      def log_proto
        Rails.logger.info("  Request Proto: #{request_proto.inspect}")
      end

      def rpc_name
        params_without_request_proto[:rpc]
      end
    end
  end
end
