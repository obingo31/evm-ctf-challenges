// SPDX-License-Identifier: UNLICENSED
object "Solver" {
    code {
        // copy runtime into memory and return it as deployed code
        datacopy(0, dataoffset("runtime"), datasize("runtime"))
        return(0, datasize("runtime"))
    }

    // runtime (12 bytes): NUMBER; PUSH1 0x00; MSTORE; GASPRICE; BALANCE; PUSH1 0x20; MSTORE; PUSH1 0x40; PUSH1 0x00; REVERT
    // hex: 43 60 00 52 3a 31 60 20 52 60 40 60 00 fd
    data "runtime" hex"436000523a31602052604060fd"
}