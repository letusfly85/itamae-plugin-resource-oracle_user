require "itamae/resource/base"
require "oci8"

module Itamae
  module Plugin
    module Resource
      class OracleUser < Itamae::Resource::Base
        define_attribute :action, default: :create_user

        define_attribute :loginuser, type: String, default_name: false
        define_attribute :loginpass, type: String, default_name: false
        define_attribute :tnsname  , type: String, default_name: false

        define_attribute :username,             type: String, default_name: false
        define_attribute :password,             type: String, default_name: false
        define_attribute :default_tablespace,   type: String, default_name: false
        define_attribute :temporary_tablespace, type: String, default_name: false
        define_attribute :user_grants,          type: Array , default: []
        define_attribute :quota_tablespaces,    type: Array , default: []

        define_attribute :if_not_exists, type: String, default_name: true

        def set_current_attributes
            begin
                @client = OCI8.new(attributes.loginuser, attributes.loginpass, attributes.tnsname)
            rescue => e
                Itamae::Logger::info e
                raise e
            end
        end

        def action_create_schema(options)
            begin
                @query =<<-EOS
create user   #{attributes.username}
identified by #{attributes.password}
default tablespace   #{attributes.default_tablespace}
temporary tablespace #{attributes.temporary_tablespace}
EOS

                results = @client.exec(@query)

            rescue Mysql2::Error => me
                Itamae::Logger.info me.message
            end

            if attributes.with_grants
                action_grants2schema(options)
            end
        end

        def action_grants2schema(options)
            attributes.user_grants.each do |privilige|
                @query = "grant #{privilige} to #{attributes.username}"

                results = @client.query(@query)
            end
        end

        def action_quota2schema(options)
            attributes.user_quota.each do |quota_set|
                @query =<<-EOS
alter user #{attributes.username} quota #{quota_set[:limit]} on #{quota_set[:tablespace_name]}"
EOS

                results = @client.query(@query)
            end
        end
      end
  end
end
