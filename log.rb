class Log
  #info
  def self.i(msg)
    write("I",msg)
  end
  #error
  def self.e(msg)
    write("E",msg)
  end
  #success
  def self.e(msg)
    write("S",msg)
  end

  def self.write(level,msg)
    filename = "my.log"
    file = File.open(filename, "a")
    file.write("#{level}/#{Time.now}  #{msg}\n")
    file.close
  end

end
# if !File.exist?(final_path)
#   FileUtils.makedirs(final_path)
# end
# file_rename = "#{Digest::MD5.hexdigest(Time.now.to_s)}#{File.extname(params[:fileimg].original_filename)}"
# file_path = "#{final_path}/#{file_rename}"
# File.open(file_path,'wb+') do |item| #用二进制对文件进行写入
#   item.write(params[:fileimg].read)
# end
