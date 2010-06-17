class String
  def tmp
    self + ".tmp"
  end

  def blank?
    self.empty? || self.strip.empty?
  end
end
