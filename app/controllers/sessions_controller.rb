class SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  skip_before_filter :ensure_signed_in

  def new
    response.headers['WWW-Authenticate'] = Rack::OpenID.build_header(
        :identifier => "https://www.google.com/accounts/o8/id",
        :required => ["http://axschema.org/contact/email",
                      "http://axschema.org/namePerson/first",
                      "http://axschema.org/namePerson/last"],
        :return_to => session_url,
        :method => 'POST')
    head 401
  end
  
  def create
    if openid = request.env[Rack::OpenID::RESPONSE]
      case openid.status
      when :success
        ax = OpenID::AX::FetchResponse.from_success_response(openid)
        if user = Subscriber.first(:conditions => { :identifier_url => openid.display_identifier })
          session[:user_id] = user.id
          redirect_to root_path
        else
          display_name = ax.get_single('http://axschema.org/namePerson/first').to_s + " " + ax.get_single('http://axschema.org/namePerson/last').to_s
          display_name.strip!
          display_name = "Engaged Citizen" if display_name == ""
          user = Subscriber.create!(:identifier_url => openid.display_identifier,
                                    :email => ax.get_single('http://axschema.org/contact/email'),
                                    :display_name => display_name)
          session[:user_id] = user.id
          redirect_to settings_path
        end
      when :failure
        render :action => 'problem'
      end
    else
      redirect_to auth_path
    end
  end
  
  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end
end