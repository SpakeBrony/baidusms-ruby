require 'baidubce/services/bos/bos_client'
require 'net/http'
require 'uri'
require 'json'
class BosAuthorizationClient
  def Authorization(canonicalURI)
    credentials = Auth::BceCredentials.new(
        'ak',
        'sk'
    )
    bucketName = ''
    conf = BceClientConfiguration.new(
        credentials,
        'sms.bj.baidubce.com'
        )
    options = {}
    headers = {}
    params = {}
    # headers['Host'] = Utils.parse_url_host(conf)
    # path = Utils.append_uri("/", canonicalURI)


    path = Utils.append_uri('/', canonicalURI)
    url, headers['Host'] = Utils.parse_url_host(conf)
    # url.insert(url.index('/') + 2, bucketName + '.')
    headers['Host'] = headers['Host']

    params['AUTHORIZATION'.downcase] = sign(conf.credentials,
                                            'POST',
                                            path,
                                            headers,
                                            params,
                                            options['timestamp'],
                                            options['expiration_in_seconds'] || 1800,
                                            options['headers_to_sign'])
    params
  end


  def sign(credentials, http_method, path, headers, params,
           timestamp = nil, expiration_in_seconds = 1800, headers_to_sign = nil)

    timestamp = Time.now.to_i if timestamp.nil?
    sign_key_info = sprintf('bce-auth-v1/%s/%s/%d',
                            credentials.access_key_id,
                            Time.at(timestamp).utc.iso8601,
                            expiration_in_seconds)
    sign_key = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'),
                                       credentials.secret_access_key, sign_key_info)
    canonical_uri = get_canonical_uri_path(path)
    canonical_querystring = Utils.get_canonical_querystring(params, true)
    canonical_headers, headers_to_sign = get_canonical_headers(headers, headers_to_sign)
    canonical_request = [http_method, canonical_uri, canonical_querystring, canonical_headers].join("\n")
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'),
                                        sign_key, canonical_request)

    headers_str = headers_to_sign.join(';') unless headers_to_sign.nil?
    sign_key_info + '/' + headers_str + '/' + signature
  end

  def get_canonical_uri_path(path)
    return '/' if path.to_s.empty?
    encoded_path = Utils.url_encode_except_slash(path)
    path[0] == '/' ? encoded_path : '/' + encoded_path
  end


  def get_canonical_headers(headers, headers_to_sign = nil)
    default = false
    if headers_to_sign.to_a.empty?
      default = true
      headers_to_sign = ['host', 'content-md5', 'content-length', 'content-type']
    end

    ret_arr = []
    headers_arr = []
    headers.each do |key, value|
      next if value.to_s.strip.empty?
      if headers_to_sign.include?(key.downcase) ||
          (default && key.downcase.to_s.start_with?(Http::BCE_PREFIX))
        str = ERB::Util.url_encode(key.downcase) + ':' + ERB::Util.url_encode(value.to_s.strip)
        ret_arr << str
        headers_arr << key.downcase
      end
    end
    ret_arr.sort!
    headers_arr.sort!
    [ret_arr.join("\n"), headers_arr]
  end
  
end
