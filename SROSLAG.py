
import re

class SROSLAG:
  
  def __init__(self):
    self.lagid = 0
    self.ports = []


  def This_Is_True(self):
    return True

  def Check_LAG_Up(self, output):
    pattern = r'([ ]+)(up|down)([ ]+)(up|down)'
    matches = re.findall(pattern, output, flags=re.MULTILINE)
    adm = ""
    opr = ""
    for item in matches:
      adm = item[1].strip()
      opr = item[3].strip()
    if (adm == "up") and (opr == "up"):
      return "UP"
    else:
      return "DOWN"

  def Discover_LAG_Ports(self, lagid, output):
    self.lagid = lagid
    pattern = r'([ ]+)([0-9]+)\/([0-9]+)\/([0-9]+)([ ]+)(up|down)([ ]+)(active|standby)([ ]+)(up|down)'
    matches = re.findall(pattern, output, flags=re.MULTILINE)
    for item in matches:
      porta = item[1].strip()
      portb = item[2].strip()
      portc = item[3].strip()
      port = "{0}/{1}/{2}".format(porta, portb, portc) 
      self.ports.append(port)
      print("Found port: {0}".format(port))
    return self.ports
      

  def Get_All_Ports_Status(self, output):
    pattern = r'(.*) ([0-9]{1,})\/([0-9]{1,})\/([0-9]{1,})([ ]+)(up|down)([ ]+)(active|standby)([ ]+)(up|down)'
    matches = re.findall(pattern, output, flags=re.MULTILINE)
    result = False
    if matches:
      result = True
      for item in matches:
        #raise Exception(item)
        porta = item[1].strip()
        portb = item[2].strip()
        portc = item[3].strip()
        adm   = item[5].strip()
        opr   = item[9].strip()
        port = "{0}/{1}/{2}".format(porta,portb,portc)
        print("port: {0}  adm: {1}  opr: {2}".format(port, adm, opr))
        result = result and (adm == "up") and (opr == "up")
    if result:
      return "UP"
    else:
      return "DOWN"


  def Check_Port_Status(self, output):
    return "UP"

  
  

    