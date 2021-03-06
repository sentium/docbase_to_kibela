class SyncDocbaseJob
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: 3

  def perform(from_updated_at, request_path=nil)
    if request_path.nil?
      # 初回はUserの再取得を行う
      User.sync_by_docbase
    end
    next_path = Post.sync_by_docbase(from_updated_at, nil, request_path)
    if next_path
      SyncDocbaseJob.perform_in(1.second, from_updated_at, next_path)
      puts "Enqueued SyncDocbaseJob #{next_path}"
    end
  rescue RateLimitException => rle
    span = (rle.rate_limit_reset_time - Time.current).to_i
    SyncDocbaseJob.perform_in(span.second, from_updated_at, request_path)
  end
end