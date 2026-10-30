source 'https://rubygems.org'

ruby file: ".ruby-version"

gem "jekyll", "~> 4.3" # installed by `gem jekyll`

gem "just-the-docs", "0.12.0" # pinned to the current release
# gem "just-the-docs"        # always download the latest release

# Data tools in assets/ruby (scrapers, sponsor_utils, sponsor_archive)
group :tools do
  gem "nokogiri", "~> 1.18"
  gem "public_suffix", ">= 6.0"
end

group :test do
  gem "minitest", "~> 5.25"
end
