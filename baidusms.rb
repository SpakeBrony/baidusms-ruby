canonicalURI = 'bce/v2/message'
    bosAuthorizationClient = BosAuthorizationClient.new
    authorization = bosAuthorizationClient.Authorization(canonicalURI)

    content_var = {'code' => '0000'}
    data = {
        'invokeId' => 'xxxxxxxxxx',

        'templateCode' => 'smsTpl:xxxxxxxxxxxxxx',

        'phoneNumber' => '13xxxxxxxx',

        'contentVar' => content_var
    }.to_json
    url_http = URI.parse('http://sms.bj.baidubce.com/bce/v2/message')
    header = {
        'Content-Type' => 'application/json',
        'Authorization' => authorization['authorization'].to_s
    }
    http = Net::HTTP.new(url_http.host, url_http.port)
    response = http.post(url_http, data, header)
    resbody = JSON.parse(response.body)
    puts resbody['code']
