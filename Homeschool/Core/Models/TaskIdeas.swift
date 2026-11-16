import Foundation

/// Starter task titles for every subject a family can choose in setup.
/// The weekly plan draws from these, so Home, the week planner and Progress always show
/// work that belongs to the child's own subjects instead of generic placeholders.
enum TaskIdeas {
    /// All starter titles for a subject. Unknown subjects still get sensible, subject-named titles.
    /// With a NIOS level, titles follow that level's syllabus (Level A/B/C, Secondary, Senior Secondary).
    static func titles(for subject: String, level: String? = nil) -> [String] {
        let key = LearningProgress.subjectKey(subject)
        if let level, let list = levelBank[level]?[key] { return list }
        if let list = bank[key] { return list }
        let name = subject.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ["Explore \(name)", "Practise \(name)", "Review \(name) notes"]
    }

    /// Picks a title by rotating through the subject's list, so a subject does not repeat the same task every day.
    static func title(for subject: String, level: String? = nil, slot: Int) -> String {
        let list = titles(for: subject, level: level)
        return list[((slot % list.count) + list.count) % list.count]
    }

    /// True for titles the planner generated itself (including ones saved by earlier versions).
    static func isStock(title: String, subject: String) -> Bool {
        let name = subject.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if titles(for: subject).contains(title) || title == "Explore \(name)" { return true }
        let key = LearningProgress.subjectKey(subject)
        return levelBank.values.contains { $0[key]?.contains(title) == true }
    }

    // MARK: - Bank

    private static let languageNames = [
        "Hindi", "Sanskrit", "Urdu", "Regional language", "Bengali", "Marathi", "Telugu", "Gujarati",
        "Punjabi", "Assamese", "Nepali", "Odia", "Malayalam", "Kannada", "Arabic", "Persian", "Tamil"
    ]

    private static let bank: [String: [String]] = {
        var list: [String: [String]] = [
            // Core academics
            "mathematics": ["Fractions in practice", "Number patterns and puzzles", "Solve a real-life word problem", "Shapes and measurement"],
            "basic mathematics": ["Counting and number sense", "Shapes around us", "Add and subtract with objects", "Measure with everyday things"],
            "english": ["Explain an idea", "Read and retell a short story", "Write a paragraph about your day", "Grow your word bank"],
            "science": ["Observe and predict", "A simple home experiment", "Living things around us", "Forces and motion"],
            "science & technology": ["Observe and predict", "A simple home experiment", "Everyday technology", "Forces and motion"],
            "social science": ["Map and place study", "A day in history", "How communities work", "Our rights and duties"],
            "environmental studies (evs)": ["Nature walk and notes", "Plants and animals nearby", "Water and waste at home", "Seasons and weather"],
            // Skills and arts
            "computer skills": ["Typing and keyboard practice", "Explore Python data types", "Make a simple presentation", "Safe and smart internet use"],
            "computer science": ["Explore Python data types", "Logic and flowcharts", "Write a small program", "How computers store data"],
            "basic computing": ["Parts of a computer", "Files and folders", "Word processing practice", "Spreadsheet basics"],
            "art & craft": ["Create a repeating pattern", "Sketch from observation", "Colour mixing play", "Make something from recycled items"],
            "creative crafts": ["Paper craft project", "Create a repeating pattern", "Natural-material collage", "Simple stitching or weaving"],
            "painting": ["Create a repeating pattern", "Colour wash and blending", "Paint a landscape", "Still life sketch and paint"],
            "cutting & tailoring": ["Take and record measurements", "Learn basic stitches", "Pattern drafting practice", "Mend or finish a small item"],
            "basic agriculture": ["Soil and seed basics", "Plan a small garden bed", "Water and care for plants", "Compost and mulching"],
            "vermicomposting": ["Set up a worm bin", "Feed and check the worms", "Moisture and temperature check", "Use compost in the garden"],
            "basic plumbing & electrical wiring": ["Tools and safety rules", "Read a simple circuit", "Pipes and fittings basics", "Home safety checks"],
            "yoga & health": ["Warm-up and breathing", "Basic asanas", "Healthy plate and routine", "Posture and stretching"],
            "yoga": ["Warm-up and breathing", "Basic asanas", "Posture and stretching", "Relaxation and focus"],
            "carpentry": ["Tools and safety", "Measure and mark wood", "Joints and fixings", "Sand and finish a small project"],
            "solar energy technician": ["How solar panels work", "Safety on site", "Read a circuit diagram", "Measure panel output"],
            "bakery & confectionery": ["Ingredients and measures", "Bread basics", "Cake and icing techniques", "Hygiene and storage"],
            "certificate in desktop publishing": ["Page layout basics", "Fonts and typography", "Design a flyer", "Images and export"],
            "data entry operations": ["Typing accuracy drill", "Spreadsheet data entry", "Format a table", "Check and correct data"],
            // Secondary and senior secondary electives
            "economics": ["Needs, wants and choices", "Read a price list", "Make a simple budget", "How markets work"],
            "business studies": ["Plan a tiny business idea", "Costs and profit", "Customer needs survey", "Record sales and stock"],
            "accountancy": ["Journal entries practice", "Ledger basics", "Trial balance", "Read a simple balance sheet"],
            "home science": ["Nutrition and meals", "A clean and safe kitchen", "Care of clothes", "Plan a family budget"],
            "psychology": ["Memory games", "Emotions and feelings", "How habits form", "Observe behaviour"],
            "indian culture & heritage": ["Festivals and traditions", "Art and architecture", "Folk stories", "Heritage places"],
            "physics": ["Motion and forces", "Light and optics", "Electricity basics", "Work, energy and power"],
            "chemistry": ["Matter and its states", "Acids, bases and salts", "Chemical reactions", "The periodic table"],
            "biology": ["Cells and tissues", "Human body systems", "Plants and photosynthesis", "Genetics basics"],
            "history": ["Timeline of a period", "Sources and evidence", "Leaders and movements", "Compare two eras"],
            "geography": ["Map reading", "Climate and weather", "Landforms and rivers", "Resources and people"],
            "political science": ["The Constitution", "Government and elections", "Rights and duties", "How laws are made"],
            "environmental science": ["Ecosystems", "Pollution and solutions", "Natural resources", "A conservation case study"],
            "mass communication": ["Spot media bias", "Write a news report", "Interview practice", "Plan a short broadcast"],
            "tourism": ["Plan a trip", "Heritage sites", "Hospitality basics", "Travel budget"],
            "introduction to law": ["Sources of law", "Fundamental rights", "A case study", "How courts are structured"],
            "library & information science": ["Classify books", "Catalogue practice", "Find reliable sources", "Digital library tools"],
            "military studies": ["Leadership principles", "Map and compass", "Discipline and teamwork", "A campaign case study"],
            "military history": ["Timeline of a conflict", "Key strategies", "Notable commanders", "Impact on society"],
            "sociology": ["Family and society", "Social groups", "Culture and change", "A simple survey"],
            "physical education": ["Fitness warm-up", "Skill drill", "Rules of a sport", "Track your progress"]
        ]
        for language in languageNames {
            list[language.lowercased()] = [
                "Read a short passage in \(language)", "Practise new \(language) words",
                "Write a few sentences in \(language)", "Listen and speak in \(language)"
            ]
        }
        return list
    }()

    // MARK: - NIOS syllabus by level

    private static func languageTopics(_ language: String, level: String) -> [String] {
        switch level {
        case "Level A":
            return ["Letters and sounds in \(language)", "Read simple words in \(language)",
                    "Rhymes and stories in \(language)", "Copy and write short sentences in \(language)"]
        case "Level B":
            return ["Read a short story in \(language)", "\(language) words and their meanings",
                    "Write about your family in \(language)", "Simple \(language) grammar practice"]
        case "Level C":
            return ["Read a prose lesson in \(language)", "\(language) grammar: nouns, verbs and tenses",
                    "Write a letter or paragraph in \(language)", "Poem and listening practice in \(language)"]
        case "Grade 10":
            return ["Prose lesson and comprehension in \(language)", "\(language) grammar and vocabulary",
                    "Letter, notice and essay writing in \(language)", "Poetry appreciation in \(language)"]
        default:
            return ["Literature reading in \(language)", "Advanced \(language) grammar",
                    "Essay and report writing in \(language)", "Unseen passage practice in \(language)"]
        }
    }

    private static let levelBank: [String: [String: [String]]] = {
        var levels: [String: [String: [String]]] = [
            // Open Basic Education, Level A (Classes 1 to 3)
            "Level A": [
                "basic mathematics": ["Count and write numbers 1 to 100", "Add with objects and pictures", "Subtract with objects and pictures", "Shapes around us", "Time and money basics", "Measure length with everyday things"],
                "environmental studies (evs)": ["Myself and my family", "Plants and animals around us", "Healthy food and cleanliness", "Where does water come from?", "Seasons and weather", "Helpers in our community"],
                "computer skills": ["Know the parts of a computer", "Mouse and keyboard practice", "Draw a picture in Paint"],
                "creative crafts": ["Paper folding", "Colouring and drawing", "Clay modelling", "Make a collage with leaves"]
            ],
            // Level B (Classes 4 to 5)
            "Level B": [
                "mathematics": ["Multiplication tables and practice", "Division with remainders", "Fractions and parts of a whole", "Decimals and money", "Time, calendar and measurement", "Shapes, area and perimeter", "Read a simple bar graph"],
                "environmental studies (evs)": ["Our environment and its needs", "Food, nutrition and health", "Natural resources and their use", "Transport and communication", "Our community and government", "Plants, animals and habitats"],
                "computer skills": ["Use Paint to design a card", "Type a paragraph in a word processor", "Files and folders", "Safe use of the internet"],
                "cutting & tailoring": ["Know your sewing tools", "Basic hand stitches", "Sew a button", "Make a small pouch"],
                "basic agriculture": ["Soil types and seeds", "Sow seeds in a pot", "Watering and plant care", "Kitchen garden plan"],
                "vermicomposting": ["Why compost kitchen waste?", "Set up a worm bin", "Feed and care for the worms", "Use the compost for plants"]
            ],
            // Level C (Classes 6 to 8)
            "Level C": [
                "mathematics": ["Integers and their operations", "Fractions and decimals", "Ratio and proportion", "Introduction to algebra", "Lines, angles and triangles", "Perimeter, area and volume", "Data handling and graphs"],
                "science": ["Food and nutrition in living things", "Materials and their properties", "Force, motion and simple machines", "Light, shadows and reflection", "Sound and how we hear", "Plants, animals and ecosystems", "Water, air and weather"],
                "social science": ["Early civilisations and kingdoms", "Our Earth, maps and landforms", "Our Constitution and government", "Resources and livelihoods", "India's freedom struggle", "Democracy and local government"],
                "computer skills": ["Word processing: format a document", "Spreadsheet basics: tables and totals", "Make a presentation", "Internet research and safety"],
                "cutting & tailoring": ["Take body measurements", "Basic stitches and seams", "Draft a simple pattern", "Stitch a simple garment"],
                "basic plumbing & electrical wiring": ["Tools and safety rules", "Pipes, taps and fittings", "Simple electric circuits", "Switches, fuses and home safety"],
                "vermicomposting": ["Types of earthworms", "Prepare a compost bed", "Harvest and use vermicompost", "Troubleshoot a worm bin"],
                "yoga & health": ["Warm-up and breathing exercises", "Basic asanas", "Healthy diet and hygiene", "Relaxation and focus"]
            ],
            // Secondary (Grade 10)
            "Grade 10": [
                "mathematics": ["Number systems and real numbers", "Algebra: polynomials and linear equations", "Quadratic equations", "Arithmetic progressions", "Geometry: triangles and circles", "Mensuration: area and volume", "Introduction to trigonometry", "Statistics and probability"],
                "science & technology": ["Matter in our surroundings", "Atoms, molecules and chemical reactions", "Acids, bases and salts", "Motion, force and work", "Light: reflection and refraction", "Electricity and magnetism", "Life processes and the cell", "Heredity and evolution", "Natural resources and the environment"],
                "social science": ["India: rise of nationalism", "Resources and development", "Democracy and the Constitution", "The Indian economy", "Understanding globalisation", "Contemporary India and the world"],
                "economics": ["Basic problems of an economy", "Money and banking", "Consumer rights and protection", "Poverty and employment", "Public finance and the budget"],
                "business studies": ["Introduction to business", "Forms of business organisation", "Marketing and advertising", "Banking and insurance", "Entrepreneurship basics"],
                "home science": ["Food, nutrition and meal planning", "Clothing and textiles", "Managing family resources", "Child care and development", "Health and hygiene at home"],
                "psychology": ["Understanding human behaviour", "Learning and memory", "Motivation and emotions", "Personality and adjustment"],
                "indian culture & heritage": ["Indian art and architecture", "Festivals, music and dance", "Philosophy and value traditions", "Heritage monuments of India"],
                "painting": ["Elements of art: line, shape and colour", "Colour theory and mixing", "Still life drawing", "Indian folk painting styles", "Landscape in colour"],
                "data entry operations": ["Typing speed and accuracy", "Word processing documents", "Spreadsheet data entry", "Check and correct data"],
                "accountancy": ["Accounting equation and transactions", "Journal entries", "Ledger posting", "Trial balance", "Final accounts basics"],
                "bakery & confectionery": ["Ingredients and measures", "Bread and dough basics", "Cakes and icing", "Kitchen hygiene and storage"],
                "certificate in desktop publishing": ["Page layout basics", "Fonts and typography", "Design a flyer", "Images and exporting"],
                "basic computing": ["Parts of a computer and operating system", "Files and folders", "Word processing practice", "Spreadsheet basics", "Internet and email"],
                "yoga": ["Warm-up and breathing", "Basic asanas", "Posture and stretching", "Meditation and focus"],
                "carpentry": ["Tools and safety", "Measure and mark wood", "Joints and fixings", "Sand and finish a small project"],
                "solar energy technician": ["How solar panels work", "Safety on site", "Read a circuit diagram", "Measure panel output"]
            ],
            // Senior Secondary (Grade 12)
            "Grade 12": [
                "mathematics": ["Sets, relations and functions", "Algebra: matrices and determinants", "Limits and continuity", "Differentiation", "Integration", "Vectors and 3D geometry", "Probability"],
                "physics": ["Units, measurement and kinematics", "Laws of motion and work-energy", "Gravitation and properties of matter", "Thermodynamics and waves", "Electrostatics", "Current electricity and magnetism", "Ray and wave optics", "Atoms, nuclei and semiconductors"],
                "chemistry": ["Atomic structure and periodic table", "Chemical bonding", "Thermodynamics and equilibrium", "Solutions and electrochemistry", "Chemical kinetics", "Organic chemistry basics", "Polymers and everyday chemistry"],
                "biology": ["Diversity of living organisms", "Cell structure and function", "Genetics and evolution", "Human physiology", "Plant physiology", "Ecology and environment", "Biotechnology"],
                "history": ["Ancient India timeline", "Medieval India and its rulers", "The freedom struggle", "Sources and evidence", "Modern world history"],
                "geography": ["Physical geography: landforms and climate", "Map reading and interpretation", "Human geography and population", "Resources and agriculture", "Environment and disasters"],
                "political science": ["The Constitution of India", "Union and state government", "Elections and political parties", "Rights and duties", "International relations"],
                "economics": ["Introduction to microeconomics", "Demand and supply", "National income", "Money, banking and inflation", "Indian economic development"],
                "business studies": ["Nature of business", "Management principles", "Marketing management", "Financial management", "Entrepreneurship and small business"],
                "accountancy": ["Partnership accounts", "Company accounts basics", "Financial statements", "Ratio analysis", "Cash flow statement"],
                "home science": ["Human development across life stages", "Food science and nutrition", "Textiles and clothing", "Resource management", "Home science careers"],
                "painting": ["Principles of composition", "Study of Indian art history", "Portrait and figure sketching", "Mural and miniature styles", "Create a painting portfolio piece"],
                "environmental science": ["Ecosystems and biodiversity", "Pollution and its control", "Natural resources and conservation", "Climate change", "Sustainable development case study"],
                "mass communication": ["Types of media", "Write a news report", "Interview and reporting skills", "Advertising and public relations", "Plan a short broadcast"],
                "data entry operations": ["Keyboarding and typing speed", "Spreadsheet data entry", "Database basics", "Data accuracy checks"],
                "tourism": ["Tourism industry basics", "Heritage and cultural sites", "Hospitality and customer care", "Plan a trip and budget"],
                "introduction to law": ["Sources of law", "Fundamental rights and duties", "Court structure", "Study a landmark case"],
                "library & information science": ["Classify books", "Catalogue practice", "Find reliable sources", "Digital library tools"],
                "computer science": ["Python: variables and data types", "Python: loops and functions", "Data structures: lists and dictionaries", "Databases and SQL queries", "Boolean logic and number systems", "Networks and internet basics"],
                "sociology": ["Family and society", "Social groups and institutions", "Culture and social change", "Design a simple survey"],
                "physical education": ["Fitness and warm-up", "Rules and skills of a sport", "Health and nutrition", "Track your fitness progress"],
                "military studies": ["Leadership principles", "Map and compass", "Discipline and teamwork", "A campaign case study"],
                "military history": ["Timeline of a conflict", "Key strategies", "Notable commanders", "Impact on society"]
            ]
        ]
        // English and the other languages follow each level's language syllabus.
        for level in ["Level A", "Level B", "Level C", "Grade 10", "Grade 12"] {
            for language in languageNames + ["English"] {
                levels[level, default: [:]][language.lowercased()] = languageTopics(language, level: level)
            }
        }
        return levels
    }()
}
