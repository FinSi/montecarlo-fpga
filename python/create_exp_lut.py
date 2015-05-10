from math import exp
import os
#n is length of integer part
#1.5, 0 000 0001 1000 0000 , 0000000110000000
#1.75, , 0 000 0001 1100 0000, 0000000111000000
#2.78125, 0 000 0010 1100 1000, 0 000 0010 1100 1000
def bitVectorToFixedPoint(bitVector, n):
    if len(bitVector) != 16:
        return "ERROR: LENGTH OF " + bitVector + " IS " + str(len(bitVector))
    sign = bitVector[0]  # 1 for negative, 0 for positive
    integer_part = bitVector[1:n+1]
    decimal_part_binary = bitVector[n+1:len(bitVector)]
    integer_conv = int(integer_part, 2)
    #Calculate the decimal part of the number
    decimal_part = 0.0
    exponent = -1
    for digit in decimal_part_binary:
        if digit == '1':
            print "exponent" + str(exponent)
            decimal_part = decimal_part + (2**exponent)
        exponent = exponent - 1
    print "Decimal part is " + str(decimal_part)
    total_conv = float(integer_conv)+decimal_part
    if float(sign) == 1:
        total_conv = total_conv * -1
    return total_conv

#n is the length of the integer part
#IMPORTANT: Round fixedPoint input to three decimals
def fixedPointToBitVector(fixedPoint, n):
    sign = str(0)
    if fixedPoint < 0:
        sign = str(1)
        fixedPoint = fixedPoint * -1

    integer_part = str(fixedPoint).split('.')[0]
    decimal_part = str(fixedPoint).split('.')[1]
    integer_binary = ("{0:0"+str(n)+"b}").format(int(integer_part))
    decimal_binary = ("{0:0"+str(16-1-n)+"b}").format(int(decimal_part))
    return sign+integer_binary+decimal_binary

def formatLine(firstVal,secondVal):
    hasComma = ","
    if firstVal == 65535:
        hasComma = ""
    return str(firstVal) + " => \"" + str(secondVal) + "\"" + hasComma

#n - 16, length of input bitVector
#lengthOfInteger - How many bits to reserve for the integer part
#Length of decimal part is n - lengthOfInteger - 1
#Sign bit is the very first bit

#FORMAT
#0=>"0000000000000000", the first # is the conversion of the input bit vector
# to an unsigned integer
#The second number is the e^ result of converting that index into a bit vector,
# determining its fixed point 'true' value, and finally taking e^that


def createExpLUT(lengthOfInteger, n, outputFileName=None):
    writer = None
    numberNotWritten = 0
    if outputFileName is None:
        print "WARNING: No file name specified, not writing to file"
    else:
        if os.path.exists(outputFileName):
            os.remove(outputFileName)
        print "Writing to file " + outputFileName
        writer = open(outputFileName, 'w')
        writer.write('constant exp_lut : rom := (')

    for i in range(0, (2**n)):
        #print i
        binaryString = "{0:016b}".format(i)
        #print binaryString
        fixedPoint = bitVectorToFixedPoint(binaryString, lengthOfInteger)
        expValue = round(exp(fixedPoint), 3)
        #The problem experienced here is that e^ generates values larger than
        #What can fit in our input schema
        if round(expValue, 0) >= 2**lengthOfInteger:
            numberNotWritten = numberNotWritten + 1
            return_bitvector = "0000000000000000"
        else:
            return_bitvector = fixedPointToBitVector(expValue, lengthOfInteger)
        if writer is not None:
            #Check to see if return bit vector is proper size
            if len(return_bitvector) == 16:
                writer.write(formatLine(i, return_bitvector))
                if i % 3 == 0: #even
                    writer.write("\n")
            else:
                print "ERROR: "
                print i
                print binaryString
                print fixedPoint
                print expValue
                raise ValueError("Bit vector corrupted, " + return_bitvector)
        '''
        if i == 33025:
            print "BINARY STRING : " + binaryString
            print "DECIMAL REPRESENTATION: " + str(fixedPoint)
            print "EXP VALUE: " + str(expValue)

            print "FIXED POINT REPRESENTATION: " + return_bitvector
            print "LINE TO WRITE: " + formatLine(i, return_bitvector)
        '''
    print "Number of lines not written : " + str(numberNotWritten)
    if writer is not None:
        writer.write(');')
        writer.close()
        print "Done writing file"

if __name__ == "__main__":
    print "CREATING TABLE"
    createExpLUT(4, 16, "exp_lut_table")
    #1 00000010 0000001
    #Integer of 33025, fixed point value of -2.1
    print bitVectorToFixedPoint("1000000100000001", 8)
    print fixedPointToBitVector(3.4,4)