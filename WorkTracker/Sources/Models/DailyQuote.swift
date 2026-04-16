import Foundation

struct DailyQuote {
    let text: String
    let thinker: String
    let source: String?

    /// Deterministic quote of the day — same quote all day, different each day.
    static func quoteOfTheDay() -> DailyQuote {
        let daysSinceEpoch = Calendar.zurich.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: Date()).day ?? 0
        let index = abs(daysSinceEpoch) % all.count
        return all[index]
    }

    // swiftlint:disable function_body_length
    static let all: [DailyQuote] = [

        // ---------------------------------------------------------------
        // MARK: - Karl Marx — Economic and Philosophic Manuscripts (1844)
        // ---------------------------------------------------------------
        DailyQuote(
            text: "The worker becomes all the poorer the more wealth he produces, the more his production increases in power and range.",
            thinker: "Karl Marx",
            source: "Economic and Philosophic Manuscripts (1844)"
        ),
        DailyQuote(
            text: "The production of too many useful things results in too many useless people.",
            thinker: "Karl Marx",
            source: "Economic and Philosophic Manuscripts (1844)"
        ),
        DailyQuote(
            text: "The work is external to the worker — it is not part of his nature. He does not fulfil himself in his work but denies himself.",
            thinker: "Karl Marx",
            source: "Economic and Philosophic Manuscripts (1844)"
        ),
        DailyQuote(
            text: "The less you eat, drink, buy books, go to the theatre, think, love, theorise, sing, paint, fence — the more you save and the greater becomes your capital.",
            thinker: "Karl Marx",
            source: "Economic and Philosophic Manuscripts (1844)"
        ),
        DailyQuote(
            text: "Labour produces not only commodities; it produces itself and the worker as a commodity.",
            thinker: "Karl Marx",
            source: "Economic and Philosophic Manuscripts (1844)"
        ),
        DailyQuote(
            text: "The devaluation of the world of men is in direct proportion to the increasing value of the world of things.",
            thinker: "Karl Marx",
            source: "Economic and Philosophic Manuscripts (1844)"
        ),
        DailyQuote(
            text: "The worker puts his life into the object; but now his life no longer belongs to him but to the object.",
            thinker: "Karl Marx",
            source: "Economic and Philosophic Manuscripts (1844)"
        ),
        DailyQuote(
            text: "The alienation of the worker in his product means not only that his labour becomes an object, but that it exists outside him, independently, as something alien to him.",
            thinker: "Karl Marx",
            source: "Economic and Philosophic Manuscripts (1844)"
        ),
        DailyQuote(
            text: "The worker therefore only feels himself outside his work, and in his work feels outside himself.",
            thinker: "Karl Marx",
            source: "Economic and Philosophic Manuscripts (1844)"
        ),
        DailyQuote(
            text: "His labor is therefore not voluntary, but coerced; it is forced labor.",
            thinker: "Karl Marx",
            source: "Economic and Philosophic Manuscripts (1844)"
        ),
        DailyQuote(
            text: "As a result, man only feels himself freely active in his animal functions — eating, drinking, procreating — and in his human functions he no longer feels himself to be anything but an animal.",
            thinker: "Karl Marx",
            source: "Economic and Philosophic Manuscripts (1844)"
        ),
        DailyQuote(
            text: "Political economy regards the proletarian like a horse: he must receive enough to enable him to work.",
            thinker: "Karl Marx",
            source: "Economic and Philosophic Manuscripts (1844)"
        ),
        DailyQuote(
            text: "Labour produces for the rich wonderful things — but for the worker it produces privation. It produces palaces — but for the worker, hovels.",
            thinker: "Karl Marx",
            source: "Economic and Philosophic Manuscripts (1844)"
        ),

        // ---------------------------------------------------------------
        // MARK: - Karl Marx — Das Kapital (1867–1894)
        // ---------------------------------------------------------------
        DailyQuote(
            text: "Capital is dead labor, which, vampire-like, lives only by sucking living labor, and lives the more, the more labor it sucks.",
            thinker: "Karl Marx",
            source: "Das Kapital, Vol. 1 (1867)"
        ),
        DailyQuote(
            text: "Labor in a white skin cannot emancipate itself where it is branded in a black skin.",
            thinker: "Karl Marx",
            source: "Das Kapital, Vol. 1 (1867)"
        ),
        DailyQuote(
            text: "Accumulation of wealth at one pole is at the same time accumulation of misery, agony of toil, slavery, ignorance, at the opposite pole.",
            thinker: "Karl Marx",
            source: "Das Kapital, Vol. 1 (1867)"
        ),
        DailyQuote(
            text: "The directing motive, the end and aim of capitalist production, is to extract the greatest possible amount of surplus-value.",
            thinker: "Karl Marx",
            source: "Das Kapital, Vol. 1 (1867)"
        ),
        DailyQuote(
            text: "Capitalist production is not merely the production of commodities, it is essentially the production of surplus-value.",
            thinker: "Karl Marx",
            source: "Das Kapital, Vol. 1 (1867)"
        ),
        DailyQuote(
            text: "Labour-power is a commodity which its possessor, the wage-worker, sells to the capitalist.",
            thinker: "Karl Marx",
            source: "Das Kapital, Vol. 1 (1867)"
        ),

        // ---------------------------------------------------------------
        // MARK: - Karl Marx & Friedrich Engels — The Communist Manifesto (1848)
        // ---------------------------------------------------------------
        DailyQuote(
            text: "Workers of the world, unite! You have nothing to lose but your chains.",
            thinker: "Karl Marx & Friedrich Engels",
            source: "The Communist Manifesto (1848)"
        ),
        DailyQuote(
            text: "What the bourgeoisie produces, above all, are its own grave-diggers.",
            thinker: "Karl Marx & Friedrich Engels",
            source: "The Communist Manifesto (1848)"
        ),
        DailyQuote(
            text: "In proportion as the exploitation of one individual by another is put to an end, the exploitation of one nation by another will also be put to an end.",
            thinker: "Karl Marx & Friedrich Engels",
            source: "The Communist Manifesto (1848)"
        ),
        DailyQuote(
            text: "The bourgeoisie has stripped of its halo every occupation hitherto honoured and looked up to with reverent awe.",
            thinker: "Karl Marx & Friedrich Engels",
            source: "The Communist Manifesto (1848)"
        ),
        DailyQuote(
            text: "The bourgeoisie has converted the physician, the lawyer, the priest, the poet, the man of science, into its paid wage labourers.",
            thinker: "Karl Marx & Friedrich Engels",
            source: "The Communist Manifesto (1848)"
        ),
        DailyQuote(
            text: "In bourgeois society, living labour is but a means to increase accumulated labour.",
            thinker: "Karl Marx & Friedrich Engels",
            source: "The Communist Manifesto (1848)"
        ),
        DailyQuote(
            text: "In bourgeois society capital is independent and has individuality, while the living person is dependent and has no individuality.",
            thinker: "Karl Marx & Friedrich Engels",
            source: "The Communist Manifesto (1848)"
        ),
        DailyQuote(
            text: "The bourgeoisie cannot exist without constantly revolutionising the instruments of production.",
            thinker: "Karl Marx & Friedrich Engels",
            source: "The Communist Manifesto (1848)"
        ),
        DailyQuote(
            text: "The bourgeoisie, during its rule of scarce one hundred years, has created more massive and more colossal productive forces than have all preceding generations together.",
            thinker: "Karl Marx & Friedrich Engels",
            source: "The Communist Manifesto (1848)"
        ),

        // ---------------------------------------------------------------
        // MARK: - Karl Marx — Other works
        // ---------------------------------------------------------------
        DailyQuote(
            text: "From each according to his abilities, to each according to his needs.",
            thinker: "Karl Marx",
            source: "Critique of the Gotha Programme (1875)"
        ),
        DailyQuote(
            text: "Machines were the weapon employed by the capitalists to quell the revolt of specialized labor.",
            thinker: "Karl Marx",
            source: "The Poverty of Philosophy (1847)"
        ),
        DailyQuote(
            text: "In communist society, where nobody has one exclusive sphere of activity, society regulates the general production and makes it possible for me to do one thing today and another tomorrow.",
            thinker: "Karl Marx",
            source: "The German Ideology (1846)"
        ),
        DailyQuote(
            text: "The mode of production of material life conditions the general process of social, political and intellectual life.",
            thinker: "Karl Marx",
            source: "A Contribution to the Critique of Political Economy (1859)"
        ),
        DailyQuote(
            text: "Labour is the living, form-giving fire; it is the transitoriness of things, their temporality, as their formation by living time.",
            thinker: "Karl Marx",
            source: "Grundrisse (1858)"
        ),
        DailyQuote(
            text: "Instead of the conservative motto: A fair day's wage for a fair day's work! they ought to inscribe on their banner the revolutionary watchword: Abolition of the wages system!",
            thinker: "Karl Marx",
            source: "Value, Price and Profit (1865)"
        ),
        DailyQuote(
            text: "Labour is the worker's own life-activity, the manifestation of his own life. And this life-activity he sells to another person.",
            thinker: "Karl Marx",
            source: "Wage Labour and Capital (1849)"
        ),
        DailyQuote(
            text: "The rich will do anything for the poor but get off their backs.",
            thinker: "Karl Marx",
            source: nil
        ),

        // ---------------------------------------------------------------
        // MARK: - Friedrich Engels
        // ---------------------------------------------------------------
        DailyQuote(
            text: "Labour is the prime basic condition for all human existence, and this to such an extent that, in a sense, we have to say that labour created man himself.",
            thinker: "Friedrich Engels",
            source: "The Part Played by Labour in the Transition from Ape to Man (1876)"
        ),
        DailyQuote(
            text: "Labor is the source of all wealth, the political economists assert. And it really is the source — next to nature, which supplies it with the material that it converts into wealth.",
            thinker: "Friedrich Engels",
            source: "Dialectics of Nature (1883)"
        ),
        DailyQuote(
            text: "The slave frees himself when, of all the relations of private property, he abolishes only the relation of slavery and thereby becomes a proletarian; the proletarian can free himself only by abolishing private property in general.",
            thinker: "Friedrich Engels",
            source: "The Principles of Communism (1847)"
        ),
        DailyQuote(
            text: "The division of society into an exploiting and an exploited class, a ruling and an oppressed class, was the necessary consequence of the deficient and restricted development of production.",
            thinker: "Friedrich Engels",
            source: "Anti-Dühring (1878)"
        ),
        DailyQuote(
            text: "An ounce of action is worth a ton of theory.",
            thinker: "Friedrich Engels",
            source: nil
        ),

        // ---------------------------------------------------------------
        // MARK: - Vladimir Lenin
        // ---------------------------------------------------------------
        DailyQuote(
            text: "He who does not work shall not eat.",
            thinker: "Vladimir Lenin",
            source: "The State and Revolution (1917)"
        ),
        DailyQuote(
            text: "The productivity of labor is, in the last analysis, the most important, the principal thing for the victory of the new social system.",
            thinker: "Vladimir Lenin",
            source: "A Great Beginning (1919)"
        ),
        DailyQuote(
            text: "Subbotniks are of enormous historical significance precisely because they demonstrate the conscious and voluntary initiative of the workers in raising the productivity of labor.",
            thinker: "Vladimir Lenin",
            source: "A Great Beginning (1919)"
        ),
        DailyQuote(
            text: "In every socialist revolution, after the proletariat has solved the problem of capturing power, there comes to the forefront the fundamental task of creating a social system superior to capitalism, namely, raising the productivity of labour.",
            thinker: "Vladimir Lenin",
            source: "A Great Beginning (1919)"
        ),

        // ---------------------------------------------------------------
        // MARK: - Mao Zedong
        // ---------------------------------------------------------------
        DailyQuote(
            text: "The wealth of society is created by the workers, peasants, and working intellectuals.",
            thinker: "Mao Zedong",
            source: "Quotations (1964)"
        ),
        DailyQuote(
            text: "The people, and the people alone, are the motive force in the making of world history.",
            thinker: "Mao Zedong",
            source: "On Coalition Government (1945)"
        ),
        DailyQuote(
            text: "All our literature and art are for the masses of the people, and in the first place for the workers, peasants, and soldiers.",
            thinker: "Mao Zedong",
            source: "Talks at the Yenan Forum (1942)"
        ),

        // ---------------------------------------------------------------
        // MARK: - Hannah Arendt
        // ---------------------------------------------------------------
        DailyQuote(
            text: "Labor is the activity which corresponds to the biological process of the human body.",
            thinker: "Hannah Arendt",
            source: "The Human Condition (1958)"
        ),
        DailyQuote(
            text: "The modern age has carried with it a theoretical glorification of labor and has resulted in a factual transformation of the whole of society into a laboring society.",
            thinker: "Hannah Arendt",
            source: "The Human Condition (1958)"
        ),
        DailyQuote(
            text: "The distinction between labor and work is that labor leaves nothing behind, while work produces a durable world of things.",
            thinker: "Hannah Arendt",
            source: "The Human Condition (1958)"
        ),
        DailyQuote(
            text: "The spare time of the animal laborans is never spent in anything but consumption, and the more time left to him, the greedier and more craving his appetites.",
            thinker: "Hannah Arendt",
            source: "The Human Condition (1958)"
        ),
        DailyQuote(
            text: "It is a society of laborers which is about to be liberated from the fetters of labor, and this society does no longer know of those other higher and more meaningful activities for the sake of which this freedom would deserve to be won.",
            thinker: "Hannah Arendt",
            source: "The Human Condition (1958)"
        ),
        DailyQuote(
            text: "The last stage of a laboring society demands of its members a sheer automatic functioning.",
            thinker: "Hannah Arendt",
            source: "The Human Condition (1958)"
        ),
        DailyQuote(
            text: "What we are confronted with is the prospect of a society of laborers without labor, that is, without the only activity left to them.",
            thinker: "Hannah Arendt",
            source: "The Human Condition (1958)"
        ),

        // ---------------------------------------------------------------
        // MARK: - Rosa Luxemburg
        // ---------------------------------------------------------------
        DailyQuote(
            text: "Those who do not move, do not notice their chains.",
            thinker: "Rosa Luxemburg",
            source: nil
        ),

        // ---------------------------------------------------------------
        // MARK: - Che Guevara
        // ---------------------------------------------------------------
        DailyQuote(
            text: "Volunteer work is a school for consciousness; it is an effort carried out in society and for society as a contribution.",
            thinker: "Che Guevara",
            source: "Man and Socialism in Cuba (1965)"
        ),

        // ---------------------------------------------------------------
        // MARK: - Paul Lafargue
        // ---------------------------------------------------------------
        DailyQuote(
            text: "The proletariat has allowed itself to be degraded by the dogma of work.",
            thinker: "Paul Lafargue",
            source: "The Right to Be Lazy (1883)"
        ),

        // ---------------------------------------------------------------
        // MARK: - Leon Trotsky
        // ---------------------------------------------------------------
        DailyQuote(
            text: "The old principle: who does not work shall not eat, has been replaced by a new one: who does not obey shall not eat.",
            thinker: "Leon Trotsky",
            source: "The Revolution Betrayed (1936)"
        ),

        // ---------------------------------------------------------------
        // MARK: - Bertolt Brecht
        // ---------------------------------------------------------------
        DailyQuote(
            text: "Who built Thebes of the seven gates? In the books you will find the names of kings. Did the kings haul up the lumps of rock?",
            thinker: "Bertolt Brecht",
            source: "Questions From a Worker Who Reads (1935)"
        ),
    ]
}
