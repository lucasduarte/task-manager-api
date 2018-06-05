require 'rails_helper'

RSpec.describe 'Users API', type: :request do
  let!(:user) { create(:user) }
  let!(:auth_data) { user.create_new_auth_token }
  let(:headers) do
    { 
      'Accept' => 'application/vnd.taskmanager.v2',
      'Content-Type' => Mime[:json].to_s,
      'access-token' => auth_data['access-token'],
      'uid' => auth_data['uid'],
      'client' => auth_data['client']
    }
  end

  before { host! 'api.taskmanager.test' } 

  describe 'GET /auth/validate_token' do

    context 'when request headers are valid' do
      before do
        get "/auth/validate_token", params: {}, headers: headers
      end

      it 'returns the user' do
        expect(json_body[:data][:id].to_i).to eq(user.id)
      end

      it 'return status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when request headers are invalid' do
      before do
        headers['access-token'] = 'invalid_token'
        get "/auth/validate_token", params: {}, headers: headers
      end

      it 'return status code 401' do
        expect(response).to have_http_status(401)
      end
    end

  end

  describe 'POST /auth' do 
    before do
      post '/auth', params: user_params.to_json , headers: headers
    end
    
    context 'when request params are valid' do
      let(:user_params) { attributes_for(:user) }

      it 'return status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns json data' do 
        expect(json_body[:data][:email]).to eq(user_params[:email])
      end
    end

    context 'when request params are invalid' do
      let(:user_params) { attributes_for(:user, email: 'invalid_email@') }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns the json data for errors' do
        expect(json_body).to have_key(:errors)
      end
    end
  end

  describe 'PUT /auth' do
    before do
      put "/auth", params: user_params.to_json, headers: headers
    end

    context 'when request params are valid' do
      let(:user_params) { { email: "new@email.com" } }
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns json data for the updated user' do
        expect(json_body[:data][:email]).to eq(user_params[:email])
      end
    end

    context 'when request params are invalid' do
      let(:user_params) { attributes_for(:user, email: 'invalid_email@') }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns the json data for errors' do
        expect(json_body).to have_key(:errors)
      end
    end
  end

  describe 'DELETE /auth' do
    before do
      delete "/auth", params: {}, headers: headers
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    it 'removes user from database' do
      expect(User.find_by(id: user.id)).to be_nil
    end
  end
end