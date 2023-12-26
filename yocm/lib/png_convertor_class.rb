module Yocm
  class PNGConvertor

    PNG_EXT = ".png"

    class << self
      def convert!(files:, destination:)
        new(destination).convert(files)
      end
    end

    def initialize(destination)
      @destination = destination
    end

    def convert(files)
      total_files = files.size

      $log.info("Start Converting #{total_files} files")
      counter = 1
      files.each do |pdf|
        $log.info("Converting file #{File.basename(pdf)} (#{counter} of #{total_files})")
        convert = MiniMagick::Tool::Convert.new
        convert.density 288
        convert << pdf + "[0]"
        convert.resize "50%"
        convert.crop "1200x400+150+300"
        convert.background "white"
        convert.flatten
        convert.sharpen "0x3"
        convert.quiet
        convert.format "png"
        convert << png_path_from(pdf)
        convert.call
        counter += 1
        $log.success("#{File.basename(pdf)} successfully converted")
      end
      $log.success("All #{total_files} files converted")
    end

    private

    def png_path_from(pdf)
      File.join(@destination, File.basename(pdf).sub(".pdf", PNG_EXT))
    end
  end
end

