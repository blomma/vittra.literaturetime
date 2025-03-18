import Testing

@testable import Providers

@Test(
    "Verify input is padded to correct output",
    arguments: [
        (input: "0", paddedToLength: 2, withCharacter: "0", expectedResult: "00"),
        (input: "1", paddedToLength: 2, withCharacter: "0", expectedResult: "01"),
        (input: "01", paddedToLength: 2, withCharacter: "0", expectedResult: "01"),
        (input: "20", paddedToLength: 2, withCharacter: "0", expectedResult: "20"),
    ]
)
func leftPadWithCharacterToLengthShouldPass(
    input: String,
    paddedToLength: Int,
    withCharacter: Character,
    expectedResult: String
) {
    let result = String(input).leftPadding(toLength: paddedToLength, withPad: withCharacter)
    #expect(result == expectedResult)
}
