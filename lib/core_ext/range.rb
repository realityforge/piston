class Range
  def to_svn
    to_s.gsub(/\.{2,3}/, ':')
  end
end
