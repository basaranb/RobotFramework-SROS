
import re

class Vodafone:

  def __init__(self):
    self.memTotal = 0
    self.memInUse = 0
    self.memAvailable = 0
    self.CPUUsage = 0.0


  def TestTrue(self):
    return True

  def Get_CPU_Usage(self, output):
    result = 99999
    lines = output.split('\n', 4)
    line_total = lines[0].strip()
    line_idle = lines[1].strip() 
    line_usage = lines[2].strip()
    line_busiest = lines[3].strip()
    print(line_total)
    print(line_idle)
    print(line_usage)
    print(line_busiest)
    m = re.match( r'(.*)Usage(.*) ([0-9,.]+)%', line_usage, flags=re.MULTILINE)
    if m:
      g = m.group(3)
      result = float(m.group(3))
      self.CPUUsage = result
    return result

  def Save_Current_Memory_Status(self, output):
    lines = output.split('\n', 3)
    line_total = lines[0].strip()
    line_inuse = lines[1].strip()
    line_available = lines[2].strip()
    print(line_total)
    print(line_inuse)
    print(line_available)
    self.memTotal = self.getNumber(line_total)
    self.memInUse = self.getNumber(line_inuse)
    self.memAvailable = self.getNumber(line_available)
    #print("Total: {0}   In Use: {1}   Available: {2}".format(self.memTotal, self.memInUse, self.memAvailable))

  def getNumber(self, line):
    result = 0
    pattern = r'(.*) ([0-9,]+) bytes'
    m = re.match(pattern, line.replace(',',''), flags=0)
    if m:
      result = int(m.group(2))
    return result


  def Parse_Table(self, output):
    print("output = " + output)
    lines = output.split('\n', 9999)
    pattern = r'([ ]+)([a-zA-Z ]+) (-|\+|\|)([ ]+)([0-9]+)(\|| )([ ]+)([0-9]+)(\|| )([ ]+)([0-9]+)'
    #values = []
    for line in lines:
      m = re.match(pattern, line, flags=0)
      if m:
        title = m.group(2)
        total = m.group(5)
        allocated = m.group(7)
        free = m.group(9)
        print("title={0}  total={1}   allocated={2}  free={3}".format(title, total, allocated, free))


  def Get_Flash_and_Usage(self, output, treshold):
    m = re.findall(r'^.*Model number.*', output, re.MULTILINE)
    n = re.findall(r'^.*Percent Used.*', output, re.MULTILINE)
    for i in n:
      percent = re.match(r'(.*) ([0-9]+) (.*)', i)
      if int(treshold) <= int(percent.group(2)):
        raise Exception("One or more cards are more than 90% full")
        return 0
      elif len(m) != 3:
        raise Exception("There are less than 3 cards")
        return 0
      elif int(treshold) > int(percent.group(2)) and len(m) == 3:
        pass
    return 1

