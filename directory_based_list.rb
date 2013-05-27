module Greylist
  class DirectoryBasedList    
    def initialize(path)
      @path = path
      @path = @path << '/' unless path.end_with?('/')
    end

    def contains?(entry)
      File.exists?(@path + entry)
    end

    def add(entry)
      File.open(@path + entry, 'w') {} unless self.contains?(entry) 
    end

    def remove(entry)
      File.unlink(@path + entry) if self.contains?(entry)
    end

    def ctime(entry)
      File.ctime(@path + entry)
    end
  end
end
