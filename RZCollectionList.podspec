Pod::Spec.new do |s|
  s.name = "RZCollectionList"
  s.version = "0.7.0"
  s.summary = "A framework for transforming and combining data from Core Data and other sources and displaying it in a UITableView or UICollectionView."
  s.homepage = "http://github.com/Raizlabs/RZCollectionList"
  s.license = "MIT"
  s.authors = { "Joe Goullaud" => "joe@raizlabs.com",
                "Nick Donaldson" => "nick.donaldson@raizlabs.com" }
  s.source = { :git => "https://github.com/Raizlabs/RZCollectionList.git", :tag => s.version.to_s }
  s.source_files = 'RZCollectionList', 'RZCollectionList/**/*.{h,m}'
  s.requires_arc = true
  s.platform = :ios, '5.0'
end
