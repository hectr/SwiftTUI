import Foundation

extension Character {
    /// _Pixel block bitmap to character mapping.
    /// Based on Stefan Haustein's `TerminalImageViewer.java` -- original license: Apache 2.0.
    static let bitmaps: [(Image.PixelBlockBitmap, Character)] = [
        (0x00000000, "\u{00a0}"),
        
        // Block graphics
        
        //0xffff0000, "\u{2580}",  // upper 1/2; redundant with inverse lower 1/2

        (0x0000000f, "\u{2581}"),  // lower 1/8
        (0x000000ff, "\u{2582}"),  // lower 1/4
        (0x00000fff, "\u{2583}"),
        (0x0000ffff, "\u{2584}"),  // lower 1/2
        (0x000fffff, "\u{2585}"),
        (0x00ffffff, "\u{2586}"),  // lower 3/4
        (0x0fffffff, "\u{2587}"),
        //(0xffffffff, "\u{2588}"),  // full; redundant with inverse space
        
        (0xeeeeeeee, "\u{258a}"),  // left 3/4
        (0xcccccccc, "\u{258c}"),  // left 1/2
        (0x88888888, "\u{258e}"),  // left 1/4
        
        (0x0000cccc, "\u{2596}"),  // quadrant lower left
        (0x00003333, "\u{2597}"),  // quadrant lower right
        (0xcccc0000, "\u{2598}"),  // quadrant upper left
        //(0xccccffff, "\u{2599}"),  // 3/4 redundant with inverse 1/4
        (0xcccc3333, "\u{259a}"),  // diagonal 1/2
        //(0xffffcccc, "\u{259b}"),  // 3/4 redundant
        //(0xffff3333, "\u{259c}"),  // 3/4 redundant
        (0x33330000, "\u{259d}"),  // quadrant upper right
        //(0x3333cccc, "\u{259e}"),  // 3/4 redundant
        //(0x3333ffff, "\u{259f}"),  // 3/4 redundant
        
        // Line drawing subset: no double lines, no complex light lines
        // Simple light lines duplicated because there is no center pixel int the 4x8 matrix
        
        (0x000ff000, "\u{2501}"),  // Heavy horizontal
        (0x66666666, "\u{2503}"),  // Heavy vertical
        
        (0x00077666, "\u{250f}"),  // Heavy down and right
        (0x000ee666, "\u{2513}"),  // Heavy down and left
        (0x66677000, "\u{2517}"),  // Heavy up and right
        (0x666ee000, "\u{251b}"),  // Heavy up and left
        
        (0x66677666, "\u{2523}"),  // Heavy vertical and right
        (0x666ee666, "\u{252b}"),  // Heavy vertical and left
        (0x000ff666, "\u{2533}"),  // Heavy down and horizontal
        (0x666ff000, "\u{253b}"),  // Heavy up and horizontal
        (0x666ff666, "\u{254b}"),  // Heavy cross
        
        (0x000cc000, "\u{2578}"),  // Bold horizontal left
        (0x00066000, "\u{2579}"),  // Bold horizontal up
        (0x00033000, "\u{257a}"),  // Bold horizontal right
        (0x00066000, "\u{257b}"),  // Bold horizontal down
        
        (0x06600660, "\u{254f}"),  // Heavy double dash vertical
        
        (0x000f0000, "\u{2500}"),  // Light horizontal
        (0x0000f000, "\u{2500}"),  //
        (0x44444444, "\u{2502}"),  // Light vertical
        (0x22222222, "\u{2502}"),
        
        (0x000e0000, "\u{2574}"),  // light left
        (0x0000e000, "\u{2574}"),  // light left
        (0x44440000, "\u{2575}"),  // light up
        (0x22220000, "\u{2575}"),  // light up
        (0x00030000, "\u{2576}"),  // light right
        (0x00003000, "\u{2576}"),  // light right
        (0x00004444, "\u{2575}"),  // light down
        (0x00002222, "\u{2575}"),  // light down
        
        // Misc technical
        
        (0x44444444, "\u{23a2}"),  // [ extension
        (0x22222222, "\u{23a5}"),  // ] extension
        
        (0x0f000000, "\u{23ba}"),  // Horizontal scanline 1
        (0x00f00000, "\u{23bb}"),  // Horizontal scanline 3
        (0x00000f00, "\u{23bc}"),  // Horizontal scanline 7
        (0x000000f0, "\u{23bd}"),  // Horizontal scanline 9
        
        // Geometrical shapes.

        (0x00066000, "\u{25aa}"),  // Black small square
    ]
}
