class Log
  @spaces = ""

  def self.indent(msg, &block)
    debug(msg)
    @spaces += "  "
    begin
      block.call
    ensure
      @spaces = @spaces[0..-3]
    end
  end

  def self.debug(msg)
    print(@spaces, msg, "\n")
  end
end
    