function translateNetworkError(errcode, connecting, errdesc)
  local text
  if errcode == 111 then
    text = tr('For some reason you are unable to log in,\ncheck your internet connection and make sure the\nserver is online. If the server is online and your\ninternet connection is normal, we suggest\nre-downloading the client to remedy the problem.')
  elseif errcode == 110 then
    text = tr('For some reason you are unable to log in,\ncheck your internet connection and make sure the\nserver is online. If the server is online and your\ninternet connection is normal, we suggest\nre-downloading the client to remedy the problem.')
  elseif errcode == 1 then
    text = tr('For some reason you are unable to log in,\ncheck your internet connection and make sure the\nserver is online. If the server is online and your\ninternet connection is normal, we suggest\nre-downloading the client to remedy the problem.')
  elseif connecting then
    text = tr('For some reason you are unable to log in,\ncheck your internet connection and make sure the\nserver is online. If the server is online and your\ninternet connection is normal, we suggest\nre-downloading the client to remedy the problem.')
  else
    text = tr('For some reason you are unable to log in,\ncheck your internet connection and make sure the\nserver is online. If the server is online and your\ninternet connection is normal, we suggest\nre-downloading the client to remedy the problem.')
  end
  return text
end
