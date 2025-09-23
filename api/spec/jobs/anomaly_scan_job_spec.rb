require "rails_helper"

RSpec.describe AnomalyScanJob, type: :job do
  it "scans anomalies for the user" do
    user = create(:user)
    detector = instance_double(AnomalyDetector)
    expect(AnomalyDetector).to receive(:new).with(user).and_return(detector)
    expect(detector).to receive(:scan!)
    described_class.perform_now(user.id)
  end
end