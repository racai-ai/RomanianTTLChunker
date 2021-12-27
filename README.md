# RomanianTTLChunker
Romanian Chunker extracted from the TTL tool


TTL and all included Perl modules is (C) Radu Ion (radu@racai.ro) and ICIA 2005-2018.
Permission is granted for research and personal use ONLY.

Tokenizing, Tagging and Lemmatizing free running text: TTL

For the full TTL see the TEPROLIN repo: https://github.com/racai-ai/TEPROLIN
And directly the TTL sub-folder: https://github.com/racai-ai/TEPROLIN/tree/master/ttl

# API

``` 
http://localhost:PORT/chunker?text=MSD\nMSD\nMSD\n
```

- PORT = the port where this API is running
- MSD = part-of-speech tag in MSD format (see http://nl.ijs.si/ME/V6/msd/html/msd-ro.html or https://www.sketchengine.eu/romanian-tagset/ )
  
Output:
```
{
   "status" : "OK",
   "chunks" : "Vp#1\nNp#1\nNp#1\nNp#1\n",
   "message" : ""
}
```

The response is a JSON document with the following fields:
- status = OK if everything was in order, or ERROR
- chunks = the identified chunks associated with each token
- message = normally empty, may contain warnings or the error message in case status=ERROR

