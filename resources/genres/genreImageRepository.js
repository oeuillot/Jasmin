.pragma library

var genres=["action",
            "alternative",
            "animation",
            "blues",
            "books",
            "business",
            "childrens",
            "christian",
            "classic",
            "classical",
            "classics",
            "classicT",
            "comedy",
            "country",
            "dance",
            "documentary",
            "drama",
            "education",
            "electronic",
            "engineering",
            "finearts",
            "folk",
            "health",
            "hiphop",
            "history",
            "holiday",
            "horror",
            "humanities",
            "independent",
            "jazz",
            "jpop",
            "kayokyoku",
            "kids",
            "language",
            "latin",
            "literature",
            "mathematics",
            "music",
            "newage",
            "nonfiction",
            "pop",
            "rb",
            "reality",
            "reggae",
            "rock",
            "romance",
            "science",
            "scifi",
            "shortfilms",
            "socialScience",
            "soundtrack",
            "spoken",
            "sports",
            "teens",
            "thriller",
            "vocal",
            "western",
            "world"];

var genreMap={};

genres.forEach(function(genre) {
    var url=Qt.resolvedUrl("genre-"+genre+".jpg");

    //console.log("Map "+genre.toLowerCase()+" to url="+url);

    genreMap[genre.toLowerCase()]={
        imageURL: url
    };
});



function getGenreImageURL(title) {
    title=title.toLowerCase().replace("'", '');

    var ts=title.split(/[\s+,;-_]/);

    console.log("Get genre "+ts);

    for(var i=0;i<ts.length;i++) {
        var t=ts[i];

        var g=genreMap[t];
        if (!g) {
            continue;
        }

        console.log("=> genre "+g.imageURL);

        return g.imageURL;
    }

    return null;
}

