require "digest/sha1"
require "launchy"
begin
  require "mail"
  require "mail/check_delivery_params"
rescue LoadError
end

module LetterOpener
  class DeliveryMethod
    include Mail::CheckDeliveryParams if defined?(Mail::CheckDeliveryParams)

    @@last_rendered_mail_path = ""

    class InvalidOption < StandardError; end

    attr_accessor :settings

    def initialize(options = {})
      raise InvalidOption, "A location option is required when using the Letter Opener delivery method" if options[:location].nil?
      self.settings = options
    end

    def deliver!(mail)
      check_delivery_params(mail) if respond_to?(:check_delivery_params)

      location = File.join(settings[:location], "#{Time.now.to_f.to_s.tr('.', '_')}_#{Digest::SHA1.hexdigest(mail.encoded)[0..6]}")
      messages = Message.rendered_messages(location, mail)

      file_path = messages.first.filepath
      @@last_rendered_mail_path = file_path

      Launchy.open("file:///#{URI.parse(URI.escape(@@last_rendered_mail_path))}") unless self.class.render_only
    end

    def self.render_only=(value)
      @render_only = value
    end

    def self.render_only
      @render_only
    end

    def self.last_rendered_mail_path
      @@last_rendered_mail_path
    end

    def self.last_rendered_mail_url
      URI.parse(URI.escape(last_rendered_mail_path)).to_s
    end
  end
end
