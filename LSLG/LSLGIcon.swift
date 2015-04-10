//
//  LSLGIcon.swift
//  LSLG
//
//  Created by Morris on 4/3/15.
//  Copyright (c) 2015 WarWithinMe. All rights reserved.
//

import Cocoa

enum LSLGIconType:String {
    case Setting = "M8.63312,2.0335C8.21222,1.98883 7.78778,1.98883 7.36688,2.0335L6.93175,3.18932C6.62476,3.25749 6.32501,3.35488 6.03659,3.48018L5.00518,2.80086C4.63842,3.01213 4.29504,3.26161 3.98078,3.54514L4.30812,4.73598C4.09984,4.97157 3.91458,5.22656 3.75488,5.49745L2.52117,5.55412C2.34862,5.94061 2.21747,6.34428 2.12988,6.75838L3.09467,7.52939C3.06464,7.84241 3.06464,8.15759 3.09467,8.47061L2.12988,9.24162C2.21746,9.65572 2.34862,10.0594 2.52117,10.4459L3.75488,10.5026C3.91458,10.7734 4.09983,11.0284 4.30812,11.264L3.98078,12.4549C4.29504,12.7384 4.63842,12.9879 5.00518,13.1991L6.03659,12.5198C6.32501,12.6451 6.62477,12.7425 6.93175,12.8107L7.36688,13.9665C7.78778,14.0112 8.21222,14.0112 8.63312,13.9665L9.06825,12.8107C9.37524,12.7425 9.67499,12.6451 9.96341,12.5198L10.9948,13.1991C11.3616,12.9879 11.705,12.7384 12.0192,12.4549L11.6919,11.264C11.9002,11.0284 12.0854,10.7734 12.2451,10.5026L13.4788,10.4459C13.6514,10.0594 13.7825,9.65572 13.8701,9.24162L12.9053,8.47061C12.9354,8.15759 12.9354,7.84241 12.9053,7.52939L13.8701,6.75838C13.7825,6.34428 13.6514,5.94061 13.4788,5.55412L12.2451,5.49745C12.0854,5.22656 11.9002,4.97157 11.6919,4.73598L12.0192,3.54514C11.705,3.26161 11.3616,3.01213 10.9948,2.80086L9.96341,3.48018C9.67499,3.35488 9.37524,3.25749 9.06825,3.18932L8.63312,2.0335L8.63312,2.0335ZM8,5.93237C9.14192,5.93237 10.0676,6.85808 10.0676,7.99999C10.0676,9.14191 9.14192,10.0676 8,10.0676C6.85808,10.0676 5.93238,9.14191 5.93238,7.99999C5.93238,6.85808 6.85808,5.93237 8,5.93237L8,5.93237Z"
    case Log     = "M14,11.6455C14,11.289 13.711,11 13.3545,11L5.64545,11C5.28898,11 5,11.289 5,11.6455L5,12.3545C5,12.711 5.28898,13 5.64545,13L13.3545,13C13.711,13 14,12.711 14,12.3545L14,11.6455ZM3,11C3.55228,11 4,11.4477 4,12C4,12.5523 3.55228,13 3,13C2.44772,13 2,12.5523 2,12C2,11.4477 2.44772,11 3,11ZM14,7.64545C14,7.28898 13.711,7 13.3545,7L5.64545,7C5.28898,7 5,7.28898 5,7.64545L5,8.35455C5,8.71102 5.28898,9 5.64545,9L13.3545,9C13.711,9 14,8.71102 14,8.35455L14,7.64545ZM3,7C3.55228,7 4,7.44772 4,8C4,8.55228 3.55228,9 3,9C2.44772,9 2,8.55228 2,8C2,7.44772 2.44772,7 3,7ZM14,3.64545C14,3.28898 13.711,3 13.3545,3L5.64545,3C5.28898,3 5,3.28898 5,3.64545L5,4.35455C5,4.71102 5.28898,5 5.64545,5L13.3545,5C13.711,5 14,4.71102 14,4.35455L14,3.64545ZM3,3C3.55228,3 4,3.44772 4,4C4,4.55228 3.55228,5 3,5C2.44772,5 2,4.55228 2,4C2,3.44772 2.44772,3 3,3Z"
    case Cube    = "M14,2L2,2L2,4L2,14L14,14L14,2Z"
    case Sphere  = "M8,2C11.3137,2 14,4.68629 14,8C14,11.3137 11.3137,14 8,14C4.68629,14 2,11.3137 2,8C2,6.48068 2.56471,5.09325 3.49568,4.03616C4.5952,2.78769 6.20561,2 8,2Z"
    case Donut   = "M8,2C11.3137,2 14,4.6863 14,8C14,11.3137 11.3137,14 8,14C4.68628,14 2,11.3137 2,8C2,4.68628 4.6863,2 8,2L8,2ZM8,4.72703C9.8076,4.72703 11.273,6.19239 11.273,8C11.273,9.8076 9.80761,11.273 8,11.273C6.1924,11.273 4.72703,9.80761 4.72703,8C4.72703,6.1924 6.19239,4.72703 8,4.72703Z"
    case Suzanne = "M8.00145,13.5C7.42535,13.5 6.22238,13.4194 6.15687,13.0948C6.00315,12.3333 6.21285,11.1189 6.58562,10.0198C6.66856,9.77528 6.81246,9.32178 6.72014,9.24196C6.33902,8.91245 4.93131,8.46909 4.36617,8.04275C3.84222,7.64748 3.34817,6.92705 3.49184,6.32497C3.6426,5.69319 4.28706,5.55364 5.0051,5.12576C5.6095,4.76559 5.94833,4.27487 6.48474,4.28307C6.96168,4.29036 7.21545,5.83472 7.998,5.8388C8.78056,5.84288 9.03778,4.29036 9.51472,4.28307C10.0511,4.27487 10.39,4.7656 10.9944,5.12576C11.7124,5.55364 12.3569,5.69319 12.5076,6.32497C12.6513,6.92705 12.1572,7.64748 11.6333,8.04275C11.0681,8.46909 9.66044,8.91245 9.27932,9.24196C9.187,9.32178 9.33089,9.77528 9.41383,10.0198C9.78661,11.1189 9.9963,12.3333 9.84259,13.0948C9.77708,13.4194 8.57756,13.5 8.00145,13.5L8.00145,13.5ZM8.00415,5.39188C7.42985,5.39188 7.18549,3.67971 6.39874,3.6506C5.82952,3.62954 5.24088,4.33352 4.62426,4.69441C3.76291,5.19851 3.22154,5.44637 3.10779,6.13418C3.09146,6.23292 2.84238,7.23958 4.0105,8.21294C4.66962,8.76217 5.94379,9.10054 6.37014,9.4369C6.44196,9.49356 6.30975,9.89401 6.19789,10.1971C5.83813,9.75321 4.6564,8.98693 4.5031,8.98693C4.32145,8.98693 4.0261,8.96261 3.95385,8.96875C0.559419,9.25741 0.802695,7.07406 0.895723,6.53269C1.09323,5.38341 1.97176,5.38374 2.04383,5.38374C3.12226,5.38374 2.96826,6.16455 2.97614,6.11924C3.19257,4.87427 3.86396,2.5 7.99316,2.5C12.1223,2.5 12.8074,4.87427 13.0239,6.11924C13.0317,6.16455 12.8777,5.38374 13.9562,5.38374C14.0282,5.38374 14.9068,5.38341 15.1043,6.53269C15.1973,7.07406 15.4406,9.25742 12.0461,8.96875C11.9739,8.96261 11.6786,8.98693 11.4969,8.98693C11.3436,8.98693 10.1619,9.78957 9.80211,10.2334C9.69024,9.93037 9.55804,9.49356 9.62985,9.4369C10.0562,9.10054 11.3304,8.76217 11.9895,8.21294C13.1786,7.22212 12.9085,6.23292 12.8922,6.13418C12.7785,5.44637 12.2371,5.19851 11.3757,4.69441C10.7591,4.33352 10.1705,3.62954 9.60126,3.6506C8.8145,3.67971 8.57845,5.39188 8.00414,5.39188L8.00415,5.39188ZM4.87508,6.68448C4.88853,6.25665 5.79649,5.95847 6.13949,5.97792C6.79801,6.01525 6.92542,6.65216 6.91966,6.81412C6.89276,7.57036 6.1933,7.68922 5.97808,7.68922C4.9702,7.68922 4.87242,6.76896 4.87508,6.68448L4.87508,6.68448ZM11.1244,6.68448C11.1109,6.25665 10.203,5.95847 9.85997,5.97792C9.20145,6.01525 9.07404,6.65216 9.0798,6.81412C9.1067,7.57036 9.80617,7.68922 10.0214,7.68922C11.0293,7.68922 11.127,6.76896 11.1244,6.68448L11.1244,6.68448Z"
}

class LSLGIcon {
    
    private var type:LSLGIconType
    private var __path:CGPathRef?
    
    var path:CGPathRef {
        if let p = self.__path {
            return p
        } else {
            self.createPath()
            return self.__path!
        }
    }
    
    init(type:LSLGIconType) {
        self.type = type
    }
    
    private func createPath() {
        self.__path = PocketSVG.newPathFromDAttribute( self.type.rawValue ).takeUnretainedValue()
    }
    
}
