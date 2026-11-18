//
//  SampleData.swift
//  SoundSpots
//
//  Mock data: real song metadata (captured from the iTunes Search API) plus made-up listening
//  history around San Francisco, so the map and playlists have something to show in a demo.
//

import Foundation

enum SampleData {

    static let songs: [Song] = [
        Song(id: 1542842761, title: "Blinding Lights (Remix)", artist: "The Weeknd & ROSALÍA",
             album: "Blinding Lights (Remix) - Single",
             artworkURLString: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/61/e7/3f/61e73f94-018d-5f50-50ec-8521952bc72e/20UM1IM11629.rgb.jpg/100x100bb.jpg",
             previewURLString: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/12/73/ca/1273ca46-233a-5331-189b-25ac1d656533/mzaf_976341070785891411.plus.aac.p.m4a",
             genre: "R&B/Soul", durationMillis: 216123),
        Song(id: 1538003843, title: "Levitating", artist: "Dua Lipa",
             album: "Future Nostalgia",
             artworkURLString: "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/6c/11/d6/6c11d681-aa3a-d59e-4c2e-f77e181026ab/190295092665.jpg/100x100bb.jpg",
             previewURLString: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/59/dc/4d/59dc4dda-93ff-8f1c-c536-f005f6ea6af5/mzaf_3066686759813252385.plus.aac.p.m4a",
             genre: "Pop", durationMillis: 203808),
        Song(id: 1657869393, title: "Kill Bill", artist: "SZA",
             album: "SOS",
             artworkURLString: "https://is1-ssl.mzstatic.com/image/thumb/Music122/v4/bd/3b/a9/bd3ba9fb-9609-144f-bcfe-ead67b5f6ab3/196589564931.jpg/100x100bb.jpg",
             previewURLString: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/45/2b/ea/452bead6-c7f5-82d4-f5f7-ec876014b4cc/mzaf_2905911853279084717.plus.aac.p.m4a",
             genre: "R&B/Soul", durationMillis: 153947),
        Song(id: 1615585008, title: "As It Was", artist: "Harry Styles",
             album: "Harry's House",
             artworkURLString: "https://is1-ssl.mzstatic.com/image/thumb/Music126/v4/2a/19/fb/2a19fb85-2f70-9e44-f2a9-82abe679b88e/886449990061.jpg/100x100bb.jpg",
             previewURLString: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/67/10/16/67101606-3869-ca44-6c03-e13d6322cb51/mzaf_1135399237022217274.plus.aac.p.m4a",
             genre: "Pop", durationMillis: 167303),
        Song(id: 1771719335, title: "Me and Your Mama", artist: "Childish Gambino",
             album: "\"Awaken, My Love!\"",
             artworkURLString: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/f1/3c/d7/f13cd7ab-7319-028a-8807-5991d0b308d4/0044003187658_Cover.jpg/100x100bb.jpg",
             previewURLString: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/57/c7/c3/57c7c31f-ab47-0135-ddcf-174f8428bcd2/mzaf_11827603781619567780.plus.aac.p.m4a",
             genre: "Hip-Hop/Rap", durationMillis: 379227),
        Song(id: 6781024437, title: "Bohemian Rhapsody", artist: "Queen",
             album: "A Night At The Opera (Deluxe Edition)",
             artworkURLString: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/8b/0a/ea/8b0aea60-6f4a-195b-5958-cdf459c2333b/602527644271.jpg/100x100bb.jpg",
             previewURLString: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/4b/83/09/4b8309c3-e3b2-10bd-ea80-ec017d832503/mzaf_9752264660400108875.plus.aac.p.m4a",
             genre: "Rock", durationMillis: 354320),
        Song(id: 1746801012, title: "Espresso (On Vacation Version)", artist: "Sabrina Carpenter",
             album: "Espresso EP",
             artworkURLString: "https://is1-ssl.mzstatic.com/image/thumb/Music211/v4/57/e8/7b/57e87ba0-5057-9bb9-c247-ce7dbe426e89/24UMGIM55213.rgb.jpg/100x100bb.jpg",
             previewURLString: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/e9/4d/02/e94d0230-11ee-ef94-d2cf-a5d547bd73f4/mzaf_554140808559155562.plus.aac.p.m4a",
             genre: "Pop", durationMillis: 175459),
        Song(id: 1440891171, title: "Mr. Brightside", artist: "The Killers",
             album: "Direct Hits",
             artworkURLString: "https://is1-ssl.mzstatic.com/image/thumb/Music126/v4/11/64/9c/11649c80-2066-dba8-77a9-df7eecae26c1/17UM1IM06937.rgb.jpg/100x100bb.jpg",
             previewURLString: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/c3/a0/30/c3a03008-17c5-aa29-6c6a-5e757ccdbaa5/mzaf_6073120660767081787.plus.aac.p.m4a",
             genre: "Rock", durationMillis: 223973),
        Song(id: 617154366, title: "Get Lucky", artist: "Daft Punk, Pharrell Williams & Nile Rodgers",
             album: "Random Access Memories",
             artworkURLString: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/e8/43/5f/e8435ffa-b6b9-b171-40ab-4ff3959ab661/886443919266.jpg/100x100bb.jpg",
             previewURLString: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/57/a5/85/57a585aa-f1bc-7619-881b-f8a04a5541d5/mzaf_6906185026678279401.plus.aac.p.m4a",
             genre: "Pop", durationMillis: 369629),
        Song(id: 1440882165, title: "HUMBLE.", artist: "Kendrick Lamar",
             album: "DAMN.",
             artworkURLString: "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/ab/16/ef/ab16efe9-e7f1-66ec-021c-5592a23f0f9e/17UMGIM88793.rgb.jpg/100x100bb.jpg",
             previewURLString: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/1f/2e/37/1f2e37be-bdd0-d770-6ea4-091011a6aade/mzaf_2360827885900940865.plus.aac.p.m4a",
             genre: "Hip-Hop/Rap", durationMillis: 177000),
        Song(id: 202272624, title: "Dreams", artist: "Fleetwood Mac",
             album: "Greatest Hits",
             artworkURLString: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/d2/48/f4/d248f4ae-a7e4-a48e-1588-6617de3e8d76/mzi.izeorbmm.jpg/100x100bb.jpg",
             previewURLString: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview211/v4/b6/5a/4b/b65a4b6f-54dd-ee99-0b36-98e27d5b5dd8/mzaf_13813391014293209258.plus.aac.p.m4a",
             genre: "Rock", durationMillis: 254453),
        Song(id: 1658650802, title: "Good Days", artist: "SZA",
             album: "SOS",
             artworkURLString: "https://is1-ssl.mzstatic.com/image/thumb/Music122/v4/62/93/13/6293132e-20ff-67ab-3d1f-96bb6797a6ba/196589564955.jpg/100x100bb.jpg",
             previewURLString: "https://audio-ssl.itunes.apple.com/itunes-assets/AudioPreview221/v4/9b/32/fe/9b32fec3-fbfb-db0f-3dcf-bb089d412f23/mzaf_15200324731067771849.plus.aac.p.m4a",
             genre: "R&B/Soul", durationMillis: 278480)
    ]

    /// Builds a believable history: several places, each with its own "favorite" songs.
    static func makeHistory(now: Date = Date()) -> ListeningHistory {
        let day: TimeInterval = 24 * 60 * 60
        let home = Place(name: "Home", coordinate: Coordinate(latitude: 37.7599, longitude: -122.4148),
                         dateCreated: now.addingTimeInterval(-60 * day))
        let library = Place(name: "Campus Library", coordinate: Coordinate(latitude: 37.7219, longitude: -122.4782),
                            dateCreated: now.addingTimeInterval(-45 * day))
        let gym = Place(name: "The Gym", coordinate: Coordinate(latitude: 37.7858, longitude: -122.4064),
                        dateCreated: now.addingTimeInterval(-30 * day))
        let beach = Place(name: "Ocean Beach", coordinate: Coordinate(latitude: 37.7594, longitude: -122.5107),
                          dateCreated: now.addingTimeInterval(-20 * day))

        // (place, song index, number of plays, days ago of the first play there)
        let plan: [(Place, Int, Int, Double)] = [
            (home, 10, 6, 58), (home, 5, 4, 50), (home, 11, 3, 12), (home, 2, 2, 8),
            (library, 4, 7, 44), (library, 3, 3, 40), (library, 10, 2, 20),
            (gym, 9, 8, 29), (gym, 0, 6, 28), (gym, 7, 4, 25), (gym, 6, 2, 3),
            (beach, 8, 5, 19), (beach, 1, 3, 15), (beach, 3, 1, 2)
        ]

        var listens: [ListenEvent] = []
        for (place, songIndex, plays, firstDaysAgo) in plan where songs.indices.contains(songIndex) {
            for play in 0..<plays {
                let daysAgo = firstDaysAgo - Double(play) * (firstDaysAgo / Double(max(plays, 1)))
                listens.append(ListenEvent(song: songs[songIndex], placeID: place.id,
                                           date: now.addingTimeInterval(-daysAgo * day)))
            }
        }
        return ListeningHistory(places: [home, library, gym, beach], listens: listens)
    }
}
