require 'rails_helper'

RSpec.describe NotificationsChannel, type: :channel do
  let(:user) { create(:user) }

  before { stub_connection current_user: user }

  it 'subscribes successfully and streams from notifications' do
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from('notifications')
  end

  it 'stops all streams on unsubscribe' do
    subscribe
    unsubscribe
    expect(subscription.streams).to be_empty
  end
end
