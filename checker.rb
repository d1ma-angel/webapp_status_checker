require 'net/http'
require 'net/smtp'

CHECKING_URLS = ['https://pokupon.ua', 'https://partner.pokupon.ua']
ALERT_MAIL_RECIEVER = 'alert@pokupon.ua'
TIME_INTERVAL = 60

class Checker
  def initialize(urls, mail_reciever, interval)
    @checking_urls = urls
    @alert_mail_reciever = mail_reciever
    @time_interval = interval
    @previous_status = Array.new(urls.size, true)
    @current_status = []
  end

  def check
    loop do
      @checking_urls.each_with_index do |url, index|

        @current_status[index] = self.url_working?(url)
        if @current_status[index] != @previous_status[index]
          status = ''
          if @current_status[index]
            status = 'up'
          else
            status = 'down'
          end
          puts message = "Web-app #{url} is #{status}."

          self.send_email(status, message)
          puts "Message send"
          
          @previous_status[index] = @current_status[index]
        end
      end

      sleep(@time_interval)
    end
  end

  # Проверка доступности приложения
  def url_working?(url_str)
    url = URI(url_str.chomp.strip)
    res = Net::HTTP.get_response(url)
    res.code == '200'
  rescue
    false
  end

  def send_email(status, message, opts={})
    # Установка параметров сообщения для отправки по электронной почте
    opts[:server]      ||= ENV['mail_server']
    opts[:port]        ||= ENV['mail_port'].to_i
    opts[:login]       ||= ENV['mail_login']
    opts[:password]    ||= ENV['mail_password']
    opts[:from_domain] ||= ENV['mail_from_domain']
    opts[:from]        ||= ENV['mail_from']
    opts[:to]          ||= @alert_mail_reciever

# Формирование текста сообщения
msg = <<MESSAGE_END
From: Web-app status checker <#{opts[:from]}>
To: <#{opts[:to]}>
Subject: Web-app is #{status}

#{message}
MESSAGE_END
  
    # Отправка сообщения адресату
    Net::SMTP.start(opts[:server],      opts[:port],
                    opts[:from_domain], opts[:login],
                    opts[:password],    :plain) do |smtp|
      smtp.send_message msg, opts[:from], opts[:to]
    end
  end
end

mainObject = Checker.new(CHECKING_URLS, ALERT_MAIL_RECIEVER, TIME_INTERVAL)
mainObject.check()