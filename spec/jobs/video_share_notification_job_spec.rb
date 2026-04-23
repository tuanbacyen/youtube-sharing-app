require 'rails_helper'

RSpec.describe VideoShareNotificationJob, type: :job do
  let(:user) { create(:user, email: 'sharer@example.com') }
  let(:video) { create(:video, user: user, title: 'Test Video Title') }

  it 'broadcasts the correct payload to the notifications channel' do
    expect(ActionCable.server).to receive(:broadcast).with(
      'notifications',
      {
        type: 'new_video',
        title: 'Test Video Title',
        shared_by: 'sharer@example.com'
      }
    )
    described_class.perform_now(video.id)
  end

  it 'is queued on the default queue' do
    expect(described_class.queue_name).to eq('default')
  end
end
