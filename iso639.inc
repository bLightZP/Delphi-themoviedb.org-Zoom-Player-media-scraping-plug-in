  ISO639CodeCount   = 120;
  ISO639Codes       : Array[0..ISO639CodeCount-1] of Word =
    ($00   // Default
    ,$36   // Afrikaans
    ,$1c   // Albanian
    ,$5e   // Amharic
    ,$01   // Arabic
    ,$2b   // Armenian
    ,$4d   // Assamese
    ,$2c   // Azerbaijani
    ,$2d   // Basque
    ,$45   // Bengali (Bangla)
    ,$02   // Bulgarian
    ,$55   // Burmese
    ,$23   // Byelorussian (Belarusian)
    ,$53   // Cambodian (Khmer)
    ,$03   // Catalan
    ,$5c   // Cherokee
    ,$04   // Chinese
    ,$1a   // Croatian / Serbian
    ,$05   // Czech
    ,$06   // Danish
    ,$65   // Divehi
    ,$13   // Dutch
    ,$66   // Edo
    ,$09   // English
    ,$25   // Estonian
    ,$38   // Faeroese
    ,$29   // Farsi
    ,$0b   // Finnish
    ,$0c   // French
    ,$62   // Frisian
    ,$67   // Fulfulde
    ,$56   // Galician
    ,$37   // Georgian
    ,$07   // German
    ,$08   // Greek
    ,$74   // Guarani
    ,$47   // Gujarati
    ,$68   // Hausa
    ,$75   // Hawaiian
    ,$0d   // Hebrew
    ,$39   // Hindi
    ,$0e   // Hungarian
    ,$69   // Ibibio
    ,$0f   // Icelandic
    ,$70   // Igbo
    ,$21   // Indonesian
    ,$5d   // Inuktitut
    ,$3c   // Irish
    ,$10   // Italian
    ,$11   // Japanese
    ,$4b   // Kannada
    ,$71   // Kanuri
    ,$60   // Kashmiri
    ,$3f   // Kazakh
    ,$40   // Kirghiz
    ,$57   // Konkani
    ,$12   // Korean
    ,$54   // Laothian
    ,$76   // Latin
    ,$26   // Latvian (Lettish)
    ,$27   // Lithuanian
    ,$2f   // Macedonian
    ,$3e   // Malay
    ,$4c   // Malayalam
    ,$58   // Manipuri
    ,$3a   // Maltese
    ,$4e   // Marathi
    ,$50   // Mongolian
    ,$61   // Nepali
    ,$14   // Norwegian
    ,$48   // Oriya
    ,$72   // Oromo (Afan, Galla)
    ,$79   // Papiamentu
    ,$63   // Pashto (Pushto)
    ,$15   // Polish
    ,$16   // Portuguese
    ,$46   // Punjabi
    ,$17   // Rhaeto-Romance
    ,$18   // Romanian
    ,$19   // Russian
    ,$3b   // Sami (Lappish)
    ,$4f   // Sanskrit
    ,$59   // Sindhi
    ,$5b   // Sinhalese
    ,$1b   // Slovak
    ,$24   // Slovenian
    ,$77   // Somali
    ,$0a   // Spanish
    ,$41   // Swahili (Kiswahili)
    ,$1d   // Swedish
    ,$5a   // Syriac
    ,$64   // Tagalog
    ,$28   // Tajik
    ,$5f   // Tamazight
    ,$49   // Tamil
    ,$44   // Tatar
    ,$4a   // Telugu
    ,$1e   // Thai
    ,$51   // Tibetan
    ,$73   // Tigrinya
    ,$31   // Tsonga
    ,$1f   // Turkish
    ,$42   // Turkmen
    ,$22   // Ukrainian
    ,$20   // Urdu
    ,$43   // Uzbek
    ,$33   // Venda
    ,$2a   // Vietnamese
    ,$52   // Welsh
    ,$34   // Xhosa
    ,$78   // Yi
    ,$3d   // Yiddish
    ,$6a   // Yoruba
    ,$35   // Zulu
    ,$416  // Portuguese (BR)
    ,$C1A  // Montenegrin
    ,$404  // Chinese (traditional)
    ,$04   // Chinese bilingual - no microsoft code for this langauge, redirect to simplified chinese
    ,$1000 // Portuguese (MZ)
    ,$00); // No Language




  ISO639_2Codes : Array[0..ISO639CodeCount-1] of String =
    ('',   // Default
    'af',   // Afrikaans
    'sq',   // Albanian
    'am',   // Amharic
    'ar',   // Arabic
    'hy',   // Armenian
    'as',   // Assamese
    'az',   // Azerbaijani
    'eu',   // Basque
    'bn',   // Bengali (Bangla)
    'bg',   // Bulgarian
    'my',   // Burmese
    'be',   // Byelorussian (Belarusian)
    'km',   // Cambodian (Khmer)
    'ca',   // Catalan
    'chr',  // Cherokee
    'zh',   // Chinese
    'hr',   // Croatian / Serbian
    'cs',   // Czech
    'da',   // Danish
    'dv',   // Divehi
    'nl',   // Dutch
    'bin',  // Edo/Bini
    'en',   // English
    'et',   // Estonian
    'fo',   // Faeroese
    'fa',   // Farsi/Persian
    'fi',   // Finnish
    'fr',   // French
    'fy',   // Frisian
    'ff',   // Fulfulde / Fulah
    'gl',   // Galician
    'ka',   // Georgian
    'de',   // German
    'el',   // Greek
    'gn',   // Guarani
    'gu',   // Gujarati
    'ha',   // Hausa
    'haw',  // Hawaiian
    'he',   // Hebrew
    'hi',   // Hindi
    'hu',   // Hungarian
    'efi',  // Ibibio, code may be wrong here
    'is',   // Icelandic
    'ig',   // Igbo
    'id',   // Indonesian
    'iu',   // Inuktitut
    'ga',   // Irish
    'it',   // Italian
    'ja',   // Japanese
    'kn',   // Kannada
    'kr',   // Kanuri
    'ks',   // Kashmiri
    'kk',   // Kazakh
    'ky',   // Kirghiz
    'kok',  // Konkani
    'ko',   // Korean
    'lo',   // Laothian
    'la',   // Latin
    'lv',   // Latvian (Lettish)
    'lt',   // Lithuanian
    'mk',   // Macedonian
    'ms',   // Malay
    'ml',   // Malayalam
    'ma',   // Manipuri
    'mt',   // Maltese
    'mr',   // Marathi
    'mn',   // Mongolian
    'ne',   // Nepali
    'no',   // Norwegian
    'or',   // Oriya
    'om',   // Oromo (Afan, Galla)
    'pap',  // Papiamentu
    'ps',   // Pashto (Pushto)
    'pl',   // Polish
    'pt',   // Portuguese
    'pa',   // Punjabi/Panjabi
    'rm',   // Rhaeto-Romance
    'ro',   // Romanian
    'ru',   // Russian
    'se',   // Sami (Lappish)
    'sa',   // Sanskrit
    'sd',   // Sindhi
    'si',   // Sinhalese
    'sk',   // Slovak
    'sl',   // Slovenian
    'so',   // Somali
    'es',   // Spanish
    'sw',   // Swahili (Kiswahili)
    'sv',   // Swedish
    'sy',   // Syriac
    'tl',   // Tagalog
    'tg',   // Tajik
    'zgh',  // Tamazight
    'ta',   // Tamil
    'tt',   // Tatar
    'te',   // Telugu
    'th',   // Thai
    'bo',   // Tibetan
    'ti',   // Tigrinya
    'ts',   // Tsonga
    'tr',   // Turkish
    'tk',   // Turkmen
    'uk',   // Ukrainian
    'ur',   // Urdu
    'uz',   // Uzbek
    've',   // Venda
    'vi',   // Vietnamese
    'cy',   // Welsh
    'xh',   // Xhosa
    'ii',   // Yi
    'yi',   // Yiddish
    'yo',   // Yoruba
    'zu',   // Zulu
    'pb',   // Portuguese (BR)
    'me',   // Montenegrin
    'zt',   // Chinese (traditional)
    'ze',   // Chinese bilingual
    'pm',   // Portuguese (MZ)
    'xx');  // No language


  ISO639_3Codes : Array[0..ISO639CodeCount-1] of String =
    ('',    // Default
    'afr',  // Afrikaans
    'alb',  // Albanian
    'amh',  // Amharic
    'ara',  // Arabic
    'arm',  // Armenian
    'asm',  // Assamese
    'aze',  // Azerbaijani
    'baq',  // Basque
    'ben',  // Bengali (Bangla)
    'bul',  // Bulgarian
    'bur',  // Burmese
    'bel',  // Byelorussian (Belarusian)
    'khm',  // Cambodian (Khmer)
    'cat',  // Catalan
    'chr',  // Cherokee
    'chi',  // Chinese simplified
    'hrv',  // Croatian / Serbian
    'cze',  // Czech
    'dan',  // Danish
    'div',  // Divehi
    'dut',  // Dutch
    'bin',  // Edo/Bini
    'eng',  // English
    'est',  // Estonian
    'fao',  // Faeroese / Faroese
    'per',  // Farsi/Persian
    'fin',  // Finnish
    'fre',  // French
    'fry',  // Frisian
    'ful',  // Fulfulde / Fulah
    'glg',  // Galician
    'geo',  // Georgian
    'ger',  // German
    'ell',  // Greek
    'grn',  // Guarani
    'guj',  // Gujarati
    'hau',  // Hausa
    'haw',  // Hawaiian
    'heb',  // Hebrew
    'hin',  // Hindi
    'hun',  // Hungarian
    'efi',  // Ibibio, code may be wrong here
    'ice',  // Icelandic
    'ibo',  // Igbo
    'ind',  // Indonesian
    'iku',  // Inuktitut
    'gle',  // Irish
    'ita',  // Italian
    'jpn',  // Japanese
    'kan',  // Kannada
    'kau',  // Kanuri
    'kas',  // Kashmiri
    'kaz',  // Kazakh
    'kir',  // Kirghiz
    'kok',  // Konkani
    'kor',  // Korean
    'lao',  // Laothian
    'lat',  // Latin
    'lav',  // Latvian (Lettish)
    'lit',  // Lithuanian
    'mac',  // Macedonian
    'may',  // Malay
    'mal',  // Malayalam
    'mni',  // Manipuri
    'mlt',  // Maltese
    'mar',  // Marathi
    'mon',  // Mongolian
    'nep',  // Nepali
    'nor',  // Norwegian
    'ori',  // Oriya
    'orm',  // Oromo (Afan, Galla)
    'pap',  // Papiamentu
    'pus',  // Pashto (Pushto)
    'pol',  // Polish
    'por',  // Portuguese
    'pan',  // Punjabi/Panjabi
    'roh',  // Rhaeto-Romance
    'rum',  // Romanian
    'rus',  // Russian
    'sme',  // Sami (Lappish)
    'san',  // Sanskrit
    'snd',  // Sindhi
    'sin',  // Sinhalese
    'slo',  // Slovak
    'slv',  // Slovenian
    'som',  // Somali
    'spa',  // Spanish
    'swa',  // Swahili (Kiswahili)
    'swe',  // Swedish
    'syr',  // Syriac
    'tgl',  // Tagalog
    'tgk',  // Tajik
    'zgh',  // Tamazight
    'tam',  // Tamil
    'tat',  // Tatar
    'tel',  // Telugu
    'tha',  // Thai
    'tib',  // Tibetan
    'tir',  // Tigrinya
    'tso',  // Tsonga
    'tur',  // Turkish
    'tuk',  // Turkmen
    'ukr',  // Ukrainian
    'urd',  // Urdu
    'uzb',  // Uzbek
    'ven',  // Venda
    'vie',  // Vietnamese
    'wel',  // Welsh
    'xho',  // Xhosa
    'iii',  // Yi
    'yid',  // Yiddish
    'yor',  // Yoruba
    'zul',  // Zulu
    'pob',  // Portuguese (BR)
    'mne',  // Montenegrin
    'zht',  // Chinese (traditional)
    'zhe',  // Chinese bilingual
    'pom',  // Portuguese (MZ)
    'xxx'); // No language


  ISO639Names       : Array[0..ISO639CodeCount-1] of String =
   ('Default',
    'Afrikaans',
    'Albanian',
    'Amharic',
    'Arabic',
    'Armenian',
    'Assamese',
    'Azerbaijani',
    'Basque',
    'Bengali (Bangla)',
    'Bulgarian',
    'Burmese',
    'Byelorussian (Belarusian)',
    'Cambodian (Khmer)',
    'Catalan',
    'Cherokee',
    'Chinese',
    'Croatian / Serbian',
    'Czech',
    'Danish',
    'Divehi',
    'Dutch',
    'Edo',
    'English',
    'Estonian',
    'Faeroese',
    'Farsi',
    'Finnish',
    'French',
    'Frisian',
    'Fulfulde',
    'Galician',
    'Georgian',
    'German',
    'Greek',
    'Guarani',
    'Gujarati',
    'Hausa',
    'Hawaiian',
    'Hebrew',
    'Hindi',
    'Hungarian',
    'Ibibio',
    'Icelandic',
    'Igbo',
    'Indonesian',
    'Inuktitut',
    'Irish',
    'Italian',
    'Japanese',
    'Kannada',
    'Kanuri',
    'Kashmiri',
    'Kazakh',
    'Kirghiz',
    'Konkani',
    'Korean',
    'Laothian',
    'Latin',
    'Latvian (Lettish)',
    'Lithuanian',
    'Macedonian',
    'Malay',
    'Malayalam',
    'Manipuri',
    'Maltese',
    'Marathi',
    'Mongolian',
    'Nepali',
    'Norwegian',
    'Oriya',
    'Oromo (Afan, Galla)',
    'Papiamentu',
    'Pashto (Pushto)',
    'Polish',
    'Portuguese',
    'Punjabi',
    'Rhaeto-Romance',
    'Romanian',
    'Russian',
    'Sami (Lappish)',
    'Sanskrit',
    'Sindhi',
    'Sinhalese',
    'Slovak',
    'Slovenian',
    'Somali',
    'Spanish',
    'Swahili (Kiswahili)',
    'Swedish',
    'Syriac',
    'Tagalog',
    'Tajik',
    'Tamazight',
    'Tamil',
    'Tatar',
    'Telugu',
    'Thai',
    'Tibetan',
    'Tigrinya',
    'Tsonga',
    'Turkish',
    'Turkmen',
    'Ukrainian',
    'Urdu',
    'Uzbek',
    'Venda',
    'Vietnamese',
    'Welsh',
    'Xhosa',
    'Yi',
    'Yiddish',
    'Yoruba',
    'Zulu',
    'Portuguese (BR)',
    'Montenegrin',
    'Chinese (traditional)',
    'Chinese bilingual',
    'Portuguese (MZ)',
    'No Language');


  LanguageCodeCount = 106;
  LanguageCodes     : Array[0..LanguageCodeCount-1] of LCID =
    ($0000,     // 'Language Neutral',
     $0400,     // 'Process Default Language',
     $0401,     // 'Arabic (Saudi Arabia)',
     $0801,     // 'Arabic (Iraq)',
     $0c01,     // 'Arabic (Egypt)',
     $1001,     // 'Arabic (Libya)',
     $1401,     // 'Arabic (Algeria)',
     $1801,     // 'Arabic (Morocco)',
     $1c01,     // 'Arabic (Tunisia)',
     $2001,     // 'Arabic (Oman)',
     $2401,     // 'Arabic (Yemen)',
     $2801,     // 'Arabic (Syria)',
     $2c01,     // 'Arabic (Jordan)',
     $3001,     // 'Arabic (Lebanon)',
     $3401,     // 'Arabic (Kuwait)',
     $3801,     // 'Arabic (U.A.E.)',
     $3c01,     // 'Arabic (Bahrain)',
     $4001,     // 'Arabic (Qatar)',
     $0402,     // 'Bulgarian',
     $0403,     // 'Catalan',
     $0404,     // 'Chinese (Taiwan)',
     $0804,     // 'Chinese (PRC)',
     $0c04,     // 'Chinese (Hong Kong)',
     $1004,     // 'Chinese (Singapore)',
     $0405,     // 'Czech',
     $0406,     // 'Danish',
     $0407,     // 'German (Standard)',
     $0807,     // 'German (Swiss)',
     $0c07,     // 'German (Austrian)',
     $1007,     // 'German (Luxembourg)',
     $1407,     // 'German (Liechtenstein)',
     $0408,     // 'Greek',
     $0409,     // 'English (United States)',
     $0809,     // 'English (United Kingdom)',
     $0c09,     // 'English (Australian)',
     $1009,     // 'English (Canadian)',
     $1409,     // 'English (New Zealand)',
     $1809,     // 'English (Ireland)',
     $1c09,     // 'English (South Africa)',
     $2009,     // 'English (Jamaica)',
     $2409,     // 'English (Caribbean)',
     $2809,     // 'English (Belize)',
     $2c09,     // 'English (Trinidad)',
     $040a,     // 'Spanish (Traditional Sort)',
     $080a,     // 'Spanish (Mexican)',
     $0c0a,     // 'Spanish (Modern Sort)',
     $100a,     // 'Spanish (Guatemala)',
     $140a,     // 'Spanish (Costa Rica)',
     $180a,     // 'Spanish (Panama)',
     $1c0a,     // 'Spanish (Dominican Republic)',
     $200a,     // 'Spanish (Venezuela)',
     $240a,     // 'Spanish (Colombia)',
     $280a,     // 'Spanish (Peru)',
     $2c0a,     // 'Spanish (Argentina)',
     $300a,     // 'Spanish (Ecuador)',
     $340a,     // 'Spanish (Chile)',
     $380a,     // 'Spanish (Uruguay)',
     $3c0a,     // 'Spanish (Paraguay)',
     $400a,     // 'Spanish (Bolivia)',
     $440a,     // 'Spanish (El Salvador)',
     $480a,     // 'Spanish (Honduras)',
     $4c0a,     // 'Spanish (Nicaragua)',
     $500a,     // 'Spanish (Puerto Rico)',
     $040b,     // 'Finnish',
     $040c,     // 'French (Standard)',
     $080c,     // 'French (Belgian)',
     $0c0c,     // 'French (Canadian)',
     $100c,     // 'French (Swiss)',
     $140c,     // 'French (Luxembourg)',
     $040d,     // 'Hebrew',
     $040e,     // 'Hungarian',
     $040f,     // 'Icelandic',
     $0410,     // 'Italian (Standard)',
     $0810,     // 'Italian (Swiss)',
     $0411,     // 'Japanese',
     $0412,     // 'Korean',
     $0812,     // 'Korean (JoHab)',
     $0413,     // 'Dutch (Standard)',
     $0813,     // 'Dutch (Belgian)',
     $0414,     // 'Norwegian (Bokmal)',
     $0814,     // 'Norwegian (Nynorsk)',
     $0415,     // 'Polish',
     $0416,     // 'Portuguese (Brazilian)',
     $0816,     // 'Portuguese (Standard)',
     $0418,     // 'Romanian',
     $0419,     // 'Russian',
     $041a,     // 'Croatian',
     $0c1a,     // 'Serbian',
     $041b,     // 'Slovak',
     $041c,     // 'Albanian',
     $041d,     // 'Swedish',
     $081d,     // 'Swedish (Finland)',
     $041e,     // 'Thai',
     $041f,     // 'Turkish',
     $0421,     // 'Indonesian',
     $0422,     // 'Ukrainian',
     $0423,     // 'Belarusian',
     $0424,     // 'Slovenian',
     $0425,     // 'Estonian',
     $0426,     // 'Latvian',
     $0427,     // 'Lithuanian',
     $081a,     // 'Serbian',
     $0429,     // 'Farsi',
     $042d,     // 'Basque',
     $0436,     // 'Afrikaans',
     $0438);    // 'Faeroese');

  LanguageNames : Array[0..LanguageCodeCount-1] of String =
    ('Language Neutral',
     'Process Default Language',
     'Arabic (Saudi Arabia)',
     'Arabic (Iraq)',
     'Arabic (Egypt)',
     'Arabic (Libya)',
     'Arabic (Algeria)',
     'Arabic (Morocco)',
     'Arabic (Tunisia)',
     'Arabic (Oman)',
     'Arabic (Yemen)',
     'Arabic (Syria)',
     'Arabic (Jordan)',
     'Arabic (Lebanon)',
     'Arabic (Kuwait)',
     'Arabic (U.A.E.)',
     'Arabic (Bahrain)',
     'Arabic (Qatar)',
     'Bulgarian',
     'Catalan',
     'Chinese (Taiwan)',
     'Chinese (PRC)',
     'Chinese (Hong Kong)',
     'Chinese (Singapore)',
     'Czech',
     'Danish',
     'German (Standard)',
     'German (Swiss)',
     'German (Austrian)',
     'German (Luxembourg)',
     'German (Liechtenstein)',
     'Greek',
     'English (United States)',
     'English (United Kingdom)',
     'English (Australian)',
     'English (Canadian)',
     'English (New Zealand)',
     'English (Ireland)',
     'English (South Africa)',
     'English (Jamaica)',
     'English (Caribbean)',
     'English (Belize)',
     'English (Trinidad)',
     'Spanish (Traditional Sort)',
     'Spanish (Mexican)',
     'Spanish (Modern Sort)',
     'Spanish (Guatemala)',
     'Spanish (Costa Rica)',
     'Spanish (Panama)',
     'Spanish (Dominican Republic)',
     'Spanish (Venezuela)',
     'Spanish (Colombia)',
     'Spanish (Peru)',
     'Spanish (Argentina)',
     'Spanish (Ecuador)',
     'Spanish (Chile)',
     'Spanish (Uruguay)',
     'Spanish (Paraguay)',
     'Spanish (Bolivia)',
     'Spanish (El Salvador)',
     'Spanish (Honduras)',
     'Spanish (Nicaragua)',
     'Spanish (Puerto Rico)',
     'Finnish',
     'French (Standard)',
     'French (Belgian)',
     'French (Canadian)',
     'French (Swiss)',
     'French (Luxembourg)',
     'Hebrew',
     'Hungarian',
     'Icelandic',
     'Italian (Standard)',
     'Italian (Swiss)',
     'Japanese',
     'Korean',
     'Korean (JoHab)',
     'Dutch (Standard)',
     'Dutch (Belgian)',
     'Norwegian (Bokmal)',
     'Norwegian (Nynorsk)',
     'Polish',
     'Portuguese (Brazilian)',
     'Portuguese (Standard)',
     'Romanian',
     'Russian',
     'Croatian',
     'Serbian',
     'Slovak',
     'Albanian',
     'Swedish',
     'Swedish (Finland)',
     'Thai',
     'Turkish',
     'Indonesian',
     'Ukrainian',
     'Belarusian',
     'Slovenian',
     'Estonian',
     'Latvian',
     'Lithuanian',
     'Serbian',
     'Farsi',
     'Basque',
     'Afrikaans',
     'Faeroese');


