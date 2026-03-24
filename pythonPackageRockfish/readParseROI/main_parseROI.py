from fn_parseROI import fn_parseROI

def main():
    mousePath = r"C:\Users\zzhu34\Documents\tempdata\zzMeso_widefield"
    roiOrder = ["AC1", "AC2"]
    roiSize = [676, 676]

    fn_parseROI(mousePath, roiOrder, roiSize)

if __name__ == "__main__":
    main()


