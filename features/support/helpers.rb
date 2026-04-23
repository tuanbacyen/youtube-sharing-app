require 'database_cleaner/active_record'

DatabaseCleaner.strategy = :truncation

Before do
  DatabaseCleaner.start
end

After do |scenario|
  if scenario.failed?
    screenshot_dir = Rails.root.join("tmp/screenshots")
    FileUtils.mkdir_p(screenshot_dir)
    safe_name = scenario.name.gsub(/[^a-zA-Z0-9_-]/, '_')[0..80]
    path = screenshot_dir.join("#{safe_name}_#{Time.now.to_i}.png")
    begin
      page.save_screenshot(path.to_s)
      puts "\n  [screenshot] #{path}"
    rescue StandardError => e
      puts "\n  [screenshot] failed: #{e.message}"
    end
  end

  # Clear browser localStorage so React auth state does not bleed between scenarios.
  begin
    page.execute_script("window.localStorage.clear()")
  rescue StandardError
    # ignore — page may be on about:blank or not yet visited
  end

  DatabaseCleaner.clean
end
