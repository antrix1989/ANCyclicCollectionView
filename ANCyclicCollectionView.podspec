Pod::Spec.new do |s|
	s.name     = 'ANCyclicCollectionView'
	s.version  = ‘1.0.0’
	s.license  = 'MIT'
	s.summary  = ‘Cyclic collection view.’
	s.homepage = 'https://github.com/antrix1989/ANCyclicCollectionView'
	s.authors  = { 'Sergey Demchenko' => 'antrix1989@gmail.com' }
	s.source   = { :git => 'https://github.com/antrix1989/ANCyclicCollectionView.git', :tag => '1.1.0' }
	s.requires_arc = true
	s.ios.deployment_target = '6.0'
	s.source_files = '*.{h,m}'
end

