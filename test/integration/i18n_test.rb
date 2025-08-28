require 'test_helper'

class I18nTest < ActionDispatch::IntegrationTest
  setup do
    @original_load_path = I18n.load_path
    @site_name = TeSS::Config.site['title_short']
    apply_overrides
    @user = users(:regular_user)
  end

  teardown do
    reset_translations
  end

  test 'can log in with email address' do
    reset_translations
    get '/users/sign_in'
    post '/users/sign_in', params: { 'user[login]' => @user.email, 'user[password]' => 'hello' }

    follow_redirect!
    assert_equal 'Logged in successfully.', flash[:notice]
  end

  test 'can log in with email address (en-AU)' do
    get '/users/sign_in'
    post '/users/sign_in', params: { 'user[login]' => @user.email, 'user[password]' => 'hello' }

    follow_redirect!
    assert_equal 'Logged in successfully!!!', flash[:notice]
  end

  test 'can logout (en-AU)' do
    get '/users/sign_in'
    post '/users/sign_in', params: { 'user[login]' => @user.email, 'user[password]' => 'hello' }

    delete '/users/sign_out'
    follow_redirect!
    assert_equal 'Logged out successfully.', flash[:notice]
  end

  test 'should show overridden translation in about page when override' do
    get about_path
    assert_select 'div.about-block p', text: "#{@site_name} registry"
  end

  test 'should show overridden translation in collections page when override' do
    get collections_path
    element = css_select('a[data-content]').first
    assert_match(/#{Regexp.escape(@site_name)} collections/, element['data-content'])
  end

  private

  def apply_overrides
    I18n.load_path += Dir[Rails.root.join('test', 'config', 'translation_override.en.yml')]
    I18n.backend.load_translations
  end

  def reset_translations
    I18n.load_path = @original_load_path
    I18n.backend.load_translations
  end
end
