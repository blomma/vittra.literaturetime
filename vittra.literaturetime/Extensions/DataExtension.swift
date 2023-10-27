import Foundation
import Compression

public extension Data {

    /// Compresses the data using the specified compression algorithm.
    func compressed(using algo: compression_algorithm = COMPRESSION_LZ4, pageSize: Int = 128) throws -> Data {
        var outputData = Data()
        let filter = try OutputFilter(.compress, using: Algorithm(rawValue: algo)!, bufferCapacity: pageSize, writingTo: { $0.flatMap({ outputData.append($0) }) })

        var index = 0
        let bufferSize = count

        while true {
            let rangeLength = Swift.min(pageSize, bufferSize - index)

            let subdata = self.subdata(in: index ..< index + rangeLength)
            index += rangeLength

            try filter.write(subdata)

            if (rangeLength == 0) { break }
        }

        return outputData
    }
    
    /// Decompresses the data using the specified compression algorithm.
    func decompressed(from algo: compression_algorithm = COMPRESSION_LZ4, pageSize: Int = 128) throws -> Data {
        var outputData = Data()
        let bufferSize = count
        var decompressionIndex = 0

        let filter = try InputFilter(.decompress, using: Algorithm(rawValue: algo)!) { (length: Int) -> Data? in
            let rangeLength = Swift.min(length, bufferSize - decompressionIndex)
            let subdata = self.subdata(in: decompressionIndex ..< decompressionIndex + rangeLength)
            decompressionIndex += rangeLength

            return subdata
        }

        while let page = try filter.readData(ofLength: pageSize) {
            outputData.append(page)
        }

        return outputData
    }
}
