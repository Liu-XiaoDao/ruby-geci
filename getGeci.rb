#-*- code:utf-8 -*-
require 'nokogiri'
require 'open-uri'
require 'rest-client'
require 'mysql2'
require 'json'
#log
require './log'

class Getlrc

  def initialize(url)
    @nowarray  = []
    @manListId = []
    @count = 0
    @db = Mysql2::Client.new(:host => 'localhost',:username => 'root',:password => '123456', :database => 'geci', :encoding => 'utf8');
    getManPage(url)
    getSong(url)
  end

  # 获取所有歌手的链接
  def getManPage(url)
    # 获取a b c d等
    urlId = url[31..url.length-5]
    # 获取所有manlist 放入数组
    html      =  RestClient.get(url).body
    doc       =  Nokogiri::HTML.parse(html)
    _lastPageUrl = doc.xpath('//*[@id="pageDiv"]/a[7]').attr('href').text
    _lastPageNum = _lastPageUrl[15..._lastPageUrl.length-4].to_i
    # 如果是其他 范围变小
    if urlId == "qita" then
      _lastPageNum = _lastPageUrl[18..._lastPageUrl.length-4].to_i
      puts _lastPageNum
    end
    (0..._lastPageNum).each do |i|
      puts "loading #{i+1}"
      getManList("http://www.kuwo.cn/geci/artist_#{urlId}_#{i}.htm")
    end
  end
  def getManList(url)
    # 获取所有歌手id  放入数组
    html  =  RestClient.get(url).body
    doc   =  Nokogiri::HTML.parse(html)
    doc.css('.songer_list > li').each do |li|
      str = li.>('a').attr('href').text
      str = str[26..str.length-2] # 把id号取出来放入数组 去掉这行就是把链接放入数组
      @manListId.push(str)
    end
  end

  # 获取所有歌手的歌曲 json格式
  def getSong(url)
    # 根据歌手列表每个id 获取id的所有歌曲
    @manListId.each do |manurl|
      # 获取歌手的总页数
      uri = "http://www.kuwo.cn/geci/wb/getJsonData?type=artSong&artistId=#{manurl}&page=1"
      html_response = nil
      open(uri) do |http|
        html_response = http.read
      end
      # sleep 1
      begin
          totalpage = JSON.parse(html_response)["totalPage"]
      rescue => e
          puts "-----这个解析出错了-----"
          puts e.message
          puts e.backtrace.join('\n')
          Log.i(e.backtrace.join('\n'))
          sleep 5
          next
      end

      # 根据总页数 每页读取歌曲id
      page = 1
      while page <= totalpage do
        url = "http://www.kuwo.cn/geci/wb/getJsonData?type=artSong&artistId=#{manurl}&page=#{page}"
        open(url) do |http|
          html_response = http.read
        end
        # sleep 1
        page = page + 1
        # http://www.kuwo.cn/yinyue/40079875
        puts html_response
        #有一个地方会解析出错，所以加上了这个
        begin
            allSongId = JSON.parse(html_response)["data"]
        rescue => e
            puts "-----这个解析出错了-----"
            puts e.message
            puts e.backtrace.join('\n')
            Log.i(e.backtrace.join('\n'))
            sleep 5
            next
        end
        allSongId.each do |item|
          url = "http://www.kuwo.cn/yinyue/#{item["rid"]}"
          puts url
          puts "解析歌词..."
          # 获取歌词
          getOneLyc(url)
        end
      end
    end
    #
  end


  # 获取一首歌的歌词 存入数据库 "http://www.kuwo.cn/yinyue/6749207"
  def getOneLyc(url)
    @count += 1
    puts "第#{@count}首"
    # 读取所有歌词 放入 @data
    parseHtml(url)
    # 把 @data 插入数据库
    insert
    # sleep 1
  end
  # 解析内容
  # url       :   链接地址
  # classname :   类名
  def parseHtml(url)
    @data = {}
    @nowarray = []
    html  =  RestClient.get(url).body
    doc   =  Nokogiri::HTML.parse(html)
    # 注意：： 没有获取到歌词 退出  有些页面没有歌词 以及版权问题 不显示歌词
    return if doc.css('.lrcItem').empty?
    _lrcname    = doc.xpath('//*[@id="lrcName"]').text
    _album      = doc.xpath('//*[@id="musiclrc"]/div[1]/p[1]/span/a').text
    _albumLink  = doc.xpath('//*[@id="musiclrc"]/div[1]/p[1]/span/a').attr('href')
    _artist     = doc.xpath('//*[@id="musiclrc"]/div[1]/p[2]/span/a').text
    _artistLink = doc.xpath('//*[@id="musiclrc"]/div[1]/p[2]/span/a').attr('href')
    # 传入具体歌词类名 放入数组
    doc.css('.lrcItem').each do |lyctxt|
      @nowarray.push(lyctxt.text)
    end
    # 转成字符串存入数据库
    @data["_lrcname"] = _lrcname
    @data["_album"] = _album
    @data["_albumLink"] = _albumLink.text
    @data["_artist"] = _artist
    @data["_artistLink"] = _artistLink.text
    @data["_lyccontent"] = @nowarray.join('|').delete("'") #注意内容中的单引号符号
  end
  # 插入数据库
  def insert
    # puts "歌词文字数量#{@data["_lyccontent"].length}"
    # 没有歌词的时候就不存入数据库
    if @data.has_key?("_lyccontent") then
      if @data["_lyccontent"].length == 0 then
        Lig.i("没有具体文字内容")
        return
      else
        puts "有内容存入数据库:歌名--#{@data["_lrcname"]}"
        puts "歌词文字数量#{@data["_lyccontent"].length}"
        results = @db.query("INSERT INTO lyc ( lycname , album , albumLink , artist , artistLink , lyccontent ) VALUES ('#{@data["_lrcname"]}' , '#{@data["_album"]}' , '#{@data["_albumLink"]}' , '#{@data["_artist"]}' , '#{@data["_artistLink"]}', '#{@data["_lyccontent"]}')")
      end
    else
      return
      puts "data没有内容"
    end
  end
end

# run = Getlrc.new("http://www.kuwo.cn/geci/artist_a.htm")
# puts run.nowarray
# 还差一个 qita 分类没有下载 用run = Getlrc.new("http://www.kuwo.cn/geci/artist_qita.htm")

# "abcdefghijklmnopqrstuvwxyz".each_char do |item|
#   puts " -----#{item}组开始------- "
#   run = Getlrc.new("http://www.kuwo.cn/geci/artist_#{item}.htm")
# end

puts "Started At #{Time.now}"
t1 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_a.htm")}
t2 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_b.htm")}
t3 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_c.htm")}
t4 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_d.htm")}
t5 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_e.htm")}
t6 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_f.htm")}
t7 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_g.htm")}
t8 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_h.htm")}
t9 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_i.htm")}
t10 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_j.htm")}
t11 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_k.htm")}
t12 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_l.htm")}
t13 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_m.htm")}
t14 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_n.htm")}
t15 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_o.htm")}
t16 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_p.htm")}
t17 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_q.htm")}
t18 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_r.htm")}
t19 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_s.htm")}
t20 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_t.htm")}
t21 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_u.htm")}
t22 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_v.htm")}
t23 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_w.htm")}
t24 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_x.htm")}
t25 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_y.htm")}
t26 = Thread.new{Getlrc.new("http://www.kuwo.cn/geci/artist_z.htm")}

t1.join
t2.join
t3.join
t4.join
t5.join
t6.join
t7.join
t8.join
t9.join
t10.join
t11.join
t12.join
t13.join
t14.join
t15.join
t16.join
t17.join
t18.join
t19.join
t20.join
t21.join
t22.join
t23.join
t24.join
t25.join
t26.join
puts "End at #{Time.now}"
