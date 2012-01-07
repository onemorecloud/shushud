module Api
  module Helpers

    def enc_json(hash)
      Yajl::Encoder.encode(hash)
    end

    def dec_time(t)
      Time.parse(CGI.unescape(t.to_s))
    end

    def dec_int(i)
      i.to_i if i
    end

    def enc_int(i)
      i.to_i if i
    end

    def enc_time(t)
      Time.parse(CGI.unescape(t.to_s))
    end

  end
end
