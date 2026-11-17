import Foundation

/// Suggested learning prompts are resolved when a task opens, so older saved weeks gain descriptions without rewriting the family's plan.
struct ActivityGuide {
    let overview: String
    let steps: [String]
    let materials: String

    init(_ overview: String, _ explore: String, _ practise: String, _ reflect: String, materials: String = "A notebook and pencil, plus any resources already chosen for this task.") {
        self.overview = overview
        steps = [explore, practise, reflect]
        self.materials = materials
    }

    static func suggested(for activity: WeekActivity) -> ActivityGuide {
        let subject = normalized(activity.subject)
        let title = normalized(activity.title)
        if ["coding", "computer skills", "computer science", "basic computing"].contains(subject), title.contains("python data types") {
            return ActivityGuide(
                "Discover how Python stores different kinds of information: whole numbers, decimals, text and true-or-false values. Use small examples to see why choosing the right type matters.",
                "Create four values: 7, 2.5, \"hello\" and True. Predict the type of each one.",
                "Use type() to check your predictions. Try adding two numbers, then joining two strings.",
                "Make a tiny learner profile using a name, an age and a yes-or-no value. Explain the type you chose for each.",
                materials: "A Python editor or interpreter. Paper works too: write the examples and predict their results.")
        }
        if ["maths", "mathematics", "basic mathematics"].contains(subject), title.contains("fractions") {
            return ActivityGuide(
                "Explore fractions as equal parts of a whole. Connect pictures, everyday objects and fraction notation before trying a few problems.",
                "Fold or draw one whole into halves, quarters and eighths. Label one part in each model.",
                "Compare pairs such as 1/2 and 2/4 using your models. Explain how different fractions can show the same amount.",
                "Make a sharing problem of your own, solve it and show your reasoning with a drawing.",
                materials: "Paper, a pencil and a few counters or other small objects.")
        }
        if ["art", "art & craft", "creative crafts", "painting"].contains(subject), title.contains("repeating pattern") {
            return ActivityGuide(
                "Create a repeating pattern using shapes, colours or marks. Explore how a small repeating unit can become a larger design.",
                "Find a pattern nearby and identify the smallest part that repeats.",
                "Choose two or three shapes and repeat your unit across a strip of paper. Change one feature to make a second design.",
                "Point out your repeating unit and explain how someone could continue the pattern.",
                materials: "Paper and coloured pencils; optional stamps, leaves or collage scraps.")
        }
        if let guide = subjectGuides[subject] { return guide }
        return ActivityGuide(
            "Work on “\(activity.title)” as part of \(activity.subject). Choose one small outcome for this session and use the task instructions or your learning resources to guide you.",
            "Read the task and decide what you want to understand or make by the end.",
            "Try one example, then work through a similar one independently. Keep a note of anything you want help with.",
            "Share what you learnt, keep one piece of work and choose a question to return to next time.")
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Every subject offered during setup has a starting prompt; custom tasks still keep their own saved steps and notes.
    private static let subjectGuides: [String: ActivityGuide] = {
        var guides: [String: ActivityGuide] = [:]
        func add(_ names: [String], _ guide: ActivityGuide) {
            for name in names { guides[normalized(name)] = guide }
        }
        add(["Maths", "Mathematics", "Basic Mathematics"], ActivityGuide(
            "Build confidence with numbers, patterns and problem solving. Use a picture or everyday example to make the idea concrete before moving to written work.",
            "Choose one idea from your current maths lesson and model it with objects or a drawing.",
            "Work through one example together, then try two similar problems with less help.",
            "Explain how you found an answer and check it in a different way."))
        add(["English"], ActivityGuide(
            "Practise understanding and expressing an idea in English. Connect reading, speaking and writing around one short text or familiar topic.",
            "Read a short passage or choose an idea you would like to explain. Pick out three useful words.",
            "Explain the idea aloud, then write a short paragraph with a clear beginning, supporting detail and ending.",
            "Read it back and improve one sentence so the meaning is clearer."))
        for language in ["Hindi", "Sanskrit", "Urdu", "Regional language", "Bengali", "Marathi", "Telugu", "Gujarati", "Punjabi", "Assamese", "Nepali", "Odia", "Malayalam", "Kannada", "Arabic", "Persian", "Tamil"] {
            add([language], ActivityGuide(
                "Build understanding and expression in \(language) through a short reading, conversation or piece of writing. Focus on a few useful words and use them in context.",
                "Choose a short text at a comfortable level. Read or listen, then identify three words to practise.",
                "Use the words in your own spoken or written sentences. Retell the main idea in your own words.",
                "Review one spelling, pronunciation or grammar point and keep a favourite sentence for revision."))
        }
        add(["Science", "Science & Technology"], ActivityGuide(
            "Practise thinking like a scientist: ask a question, make a prediction and compare it with observations. Record what you notice rather than looking for a perfect answer.",
            "Choose a familiar phenomenon, such as how a shadow changes. Ask a question and predict what you will see.",
            "Make a simple observation or comparison, changing only one thing where possible. Record results with words, numbers or a sketch.",
            "Compare the result with your prediction and suggest one question for another investigation."))
        add(["Social Science"], ActivityGuide(
            "Explore how people, places and communities connect. Use a map, photograph, short text or local example to support an explanation.",
            "Choose one place, event or community topic from your lesson and note what you already know.",
            "Study a source and record three details. Link them to a cause, change or everyday experience.",
            "Explain one connection and name the source that helped you make it."))
        add(["Computer Skills", "Computer skills", "Coding", "Computer Science", "Basic Computing"], ActivityGuide(
            "Develop a practical computing skill through a small, purposeful task. Plan the steps, try them and check the result rather than copying without understanding.",
            "Choose one tool or coding idea from your current lesson. Describe what you want it to do.",
            "Create a small example, test it and change one part to see what happens.",
            "Save your work and explain one thing you changed or fixed.", materials: "A computer or tablet with the tool for your lesson, or paper for planning the steps."))
        add(["Art", "Art & craft", "Creative Crafts", "Painting"], ActivityGuide(
            "Explore an idea through colour, shape and materials. Make a small piece of work while trying a technique of your own.",
            "Look at an object or artwork and choose a colour, shape or texture to explore.",
            "Try two quick variations, then use your favourite approach to create a small finished piece.",
            "Describe one choice you made and one thing you would try differently next time.", materials: "Paper and the drawing, painting or craft materials you already have."))
        add(["Reading"], ActivityGuide(
            "Read for understanding and enjoyment. Pause to notice how the writer builds meaning and connect the text with your own ideas.",
            "Choose a short passage or a few pages. Look at the title and predict what you might discover.",
            "Read at your own pace. Pause to explain an unfamiliar word and collect one interesting detail.",
            "Retell the main idea and explain which detail made you think."))
        add(["Environmental Studies (EVS)", "Environmental Science"], ActivityGuide(
            "Investigate a connection between living things, resources and everyday choices. Use observations from your surroundings to make the lesson real.",
            "Choose a local topic such as water use, a plant or household waste. List what you notice.",
            "Compare two examples and record a pattern or difference using a simple chart or sketch.",
            "Explain one connection and suggest a small action or question to explore next."))
        add(["Cutting & Tailoring"], ActivityGuide(
            "Practise measurement, planning and a simple textile technique. Start with a paper pattern or small fabric sample before attempting a larger project.",
            "Choose a simple shape or repair and sketch the measurements you need.",
            "Make a paper pattern, check its size and practise a basic stitch on scrap fabric with an adult's guidance.",
            "Compare your result with the pattern and note one adjustment.", materials: "Paper, a ruler and scrap fabric; use needles or scissors with an adult's guidance."))
        add(["Basic Plumbing & Electrical Wiring"], ActivityGuide(
            "Learn to recognise common plumbing and electrical components and explain their purpose. Use diagrams or disconnected models to explore how a simple system fits together.",
            "Identify and label a few components in a picture, such as a pipe, tap, switch or wire.",
            "Draw a simple water route or a battery-powered circuit and explain what each part does. Keep this a paper or disconnected-model activity with an adult.",
            "Describe one common fault shown in your learning material and which part of the system it affects.", materials: "A notebook, component pictures and, optionally, disconnected demonstration parts. No mains wiring or live equipment."))
        add(["Basic Agriculture"], ActivityGuide(
            "Explore how plants grow and how growing conditions affect them. Connect a simple observation with a practical growing task.",
            "Choose a seed or plant and identify what it needs to grow.",
            "Observe the soil, light and watering routine. Plant a seed or compare two growing conditions on paper.",
            "Record a measurement or sketch and decide what to observe next.", materials: "A plant or seeds, a notebook and optional soil and a small container."))
        add(["Vermicomposting"], ActivityGuide(
            "Explore how worms help turn suitable organic scraps into compost. Focus on identifying materials and observing a healthy compost environment.",
            "Sort pictures or examples into suitable plant scraps and materials that do not belong in a worm bin.",
            "Sketch the layers of a simple worm bin. If one is already set up, observe moisture, bedding and changes with an adult.",
            "Record one sign of decomposition and explain how compost helps soil.", materials: "Paper and compost examples or pictures; gloves and adult guidance for observing an existing bin."))
        add(["Yoga & Health", "Yoga", "Physical Education"], ActivityGuide(
            "Explore movement, coordination and healthy routines at a comfortable pace. Use familiar activities from your lesson and notice how your body responds.",
            "Choose a gentle warm-up or familiar movement sequence from your learning material.",
            "Practise slowly in a clear space, with breaks and an adult's guidance where needed.",
            "Describe how you felt before and after, and record one habit you want to continue.", materials: "A clear space, comfortable clothing and water."))
        add(["Life skills", "Home Science"], ActivityGuide(
            "Build independence through a small everyday task. Plan what you need, practise the steps and reflect on the result.",
            "Choose one suitable task, such as organising a workspace or planning a balanced meal on paper.",
            "List the materials and order of steps, then practise with the help you need.",
            "Check the result and explain one choice that made the task easier."))
        add(["Physics"], ActivityGuide(
            "Use a model or simple measurement to explore a physics idea. Connect what you observe with a rule, diagram or calculation from your lesson.",
            "Choose a concept such as motion, force or light and predict what a simple example will show.",
            "Study or carry out a suitable classroom demonstration and record measurements with units.",
            "Compare your result with the prediction and explain one source of variation."))
        add(["Chemistry"], ActivityGuide(
            "Explore how materials are described and how they change. Use diagrams, observations and your lesson examples to connect visible changes with particle ideas.",
            "Choose a material or change from your lesson and list its observable properties.",
            "Draw a particle model or compare two worked examples. Use the correct symbols or vocabulary.",
            "Explain whether the example describes a mixture, a physical change or a chemical change, using evidence."))
        add(["Biology"], ActivityGuide(
            "Investigate how a living structure or process works. Use a labelled diagram and a familiar example to connect parts with their functions.",
            "Choose a topic such as a cell, plant part or body system and identify its main components.",
            "Draw and label a model, then trace how material or information moves through it.",
            "Explain how one part supports the whole and answer a short question from your lesson."))
        add(["History", "Military History", "Indian Culture & Heritage"], ActivityGuide(
            "Explore a historical event, practice or source in context. Distinguish what the evidence shows from your interpretation.",
            "Identify the time, place and people connected with a source or event from your lesson.",
            "Create a short timeline and note a cause, an important change and a consequence.",
            "Explain one conclusion and the evidence you used to reach it."))
        add(["Geography"], ActivityGuide(
            "Explore how places and environments are connected. Use a map, diagram or data set to explain a spatial pattern.",
            "Locate a place or feature and check the map key, scale and direction.",
            "Compare two locations or draw a labelled process diagram from your lesson.",
            "Describe a pattern and give one reason that might explain it."))
        add(["Economics"], ActivityGuide(
            "Explore how people make choices with limited resources. Connect an economic idea with a familiar household or community example.",
            "Choose an idea such as scarcity, demand or opportunity cost and define it in your own words.",
            "Compare two choices or draw a simple table or graph using an example from your lesson.",
            "Explain the trade-off and describe one assumption behind your example."))
        add(["Business Studies"], ActivityGuide(
            "Explore how an organisation meets a need and makes decisions. Use a small business example to connect planning, resources and customers.",
            "Choose a familiar product or service and identify who it is for.",
            "Sketch the resources, main costs and steps needed to provide it.",
            "Explain one decision that could improve the service and how you would judge the result."))
        add(["Accountancy"], ActivityGuide(
            "Practise recording and interpreting simple business transactions. Keep the entries organised and check how each transaction affects the accounts.",
            "Review one transaction type and identify the accounts involved.",
            "Record a few sample transactions using the format from your lesson, then total the entries.",
            "Check that the figures agree and explain one entry in everyday language."))
        add(["Psychology"], ActivityGuide(
            "Explore a concept about thinking, learning or behaviour. Use a neutral everyday example to understand the idea without labelling people.",
            "Choose one concept from your lesson and write a simple definition.",
            "Compare two possible explanations for an everyday example, using the lesson as evidence.",
            "Explain what the example illustrates and one limit of your explanation."))
        add(["Sociology"], ActivityGuide(
            "Explore how groups, institutions and social experiences shape everyday life. Use an example to practise making evidence-based comparisons.",
            "Choose a concept such as roles, norms or socialisation and define it.",
            "Compare how the concept appears in two everyday settings without making assumptions about individuals.",
            "Summarise a similarity and a difference, and name the evidence you used."))
        add(["Political Science", "Introduction to Law"], ActivityGuide(
            "Explore how rules, institutions and public decisions work. Use a textbook example to distinguish a rule, a right and a responsibility.",
            "Choose an institution or principle from your lesson and identify its purpose.",
            "Read a short case or scenario and list the roles, rules and viewpoints involved.",
            "Explain a reasoned conclusion and link it to the principle you studied."))
        add(["Data Entry Operations"], ActivityGuide(
            "Practise entering and organising information accurately. Focus on a consistent format and checking your work before saving it.",
            "Create a small practice table with clear column headings and invented sample data.",
            "Enter the records, apply a consistent format and use a simple sort or formula if it fits your lesson.",
            "Check the entries against your sample and save the file with a useful name.", materials: "A spreadsheet or text editor and invented practice data."))
        add(["Certificate in Desktop Publishing"], ActivityGuide(
            "Design a clear page that combines text and images for a purpose. Practise alignment, spacing and hierarchy rather than adding decoration everywhere.",
            "Choose a one-page item, such as a poster, and sketch where the headline, image and details will go.",
            "Build the layout using consistent type sizes and alignment. Add an image you are allowed to use.",
            "Check readability and export a preview to review at its intended size.", materials: "A page-layout tool or paper, sample text and an image you can use."))
        add(["Mass Communication"], ActivityGuide(
            "Explore how a message is shaped for an audience and medium. Notice the difference between information, opinion and persuasion.",
            "Choose a short media example and identify its audience and purpose.",
            "Outline its main claim and supporting evidence, then rewrite the message for a different audience.",
            "Explain one editorial choice and check whether the source supports the claim."))
        add(["Tourism"], ActivityGuide(
            "Explore a destination through visitor needs, local context and responsible planning. Use a small itinerary to connect practical details.",
            "Choose a destination from your lesson and identify two points of interest.",
            "Plan a short visit on paper, including travel, time, access and respect for the local environment.",
            "Explain one planning choice and a detail you would verify before a real visit."))
        add(["Library & Information Science"], ActivityGuide(
            "Practise finding, organising and evaluating information. Make it easy for someone else to locate the source you used.",
            "Choose a question and identify useful keywords.",
            "Find two suitable sources or catalogue entries, compare their relevance and record their details.",
            "Organise your findings and explain which source best answers the question."))
        add(["Military Studies"], ActivityGuide(
            "Study a topic about defence institutions, organisation or historical context using your learning material. Focus on roles, terminology and evidence.",
            "Choose a concept from the lesson and identify the main terms and institutions involved.",
            "Create a labelled chart or compare two textbook examples.",
            "Explain the concept in your own words and note one question for further reading."))
        add(["Bakery & Confectionery"], ActivityGuide(
            "Explore how ingredients, measurement and method affect a baked product. Begin with a recipe plan and practise only suitable steps with an adult.",
            "Read a simple recipe and identify the purpose of the main ingredients.",
            "Measure a practice quantity or scale the recipe on paper. Put the preparation stages in order.",
            "Explain how a change in measurement or method could affect the result.", materials: "A simple recipe, paper and optional measuring tools; an adult handles hot equipment."))
        add(["Carpentry"], ActivityGuide(
            "Explore how measurement, materials and joints help make a useful object. Plan with a drawing or cardboard model before any workshop work.",
            "Choose a simple object and sketch its parts with measurements.",
            "Make a paper or cardboard model and check how the pieces fit together.",
            "Explain one choice of material or joint and one measurement you would check again.", materials: "Paper, a ruler and optional cardboard; workshop tools require qualified adult supervision."))
        add(["Solar Energy Technician"], ActivityGuide(
            "Explore how a solar-energy system turns sunlight into useful electrical energy. Use a diagram to understand the role of each component.",
            "Label a panel, controller, storage device and load in a learning diagram.",
            "Trace the energy flow and compare how shade or orientation could affect the system.",
            "Explain one design choice using the information in your lesson.", materials: "A textbook diagram or a disconnected educational model; keep this a diagram-based activity."))
        return guides
    }()
}
