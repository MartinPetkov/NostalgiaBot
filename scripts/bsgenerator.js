// All code from http://www.atrixnet.com/bs-generator.html, I take no credit for it
function randomarray(a) {
  var i;
  for (i=a.length;i--;) {
    var j = Math.floor((i+1)*Math.random());
    var temp = a[i];
    a[i] = a[j];
    a[j] = temp;
  }
return a;
}

function generateBS() {
    var adverbs = new Array (
        'appropriately', 'assertively', 'authoritatively', 'collaboratively', 'compellingly', 'competently', 'completely',
        'continually', 'conveniently', 'credibly', 'distinctively', 'dramatically', 'dynamically', 'efficiently',
        'energistically', 'enthusiastically', 'globally', 'holisticly', 'interactively', 'intrinsically', 'monotonectally',
        'objectively', 'phosfluorescently', 'proactively', 'professionally', 'progressively', 'quickly', 'rapidiously',
        'seamlessly', 'synergistically', 'uniquely', 'fungibly'
    );

    var verbs = new Array (
        'actualize', 'administrate', 'aggregate', 'architect', 'benchmark', 'brand', 'build', 'communicate', 'conceptualize',
        'coordinate', 'create', 'cultivate', 'customize', 'deliver', 'deploy', 'develop', 'disintermediate', 'disseminate',
        'drive', 'embrace', 'e-enable', 'empower', 'enable', 'engage', 'engineer', 'enhance', 'envisioneer', 'evisculate',
        'evolve', 'expedite', 'exploit', 'extend', 'fabricate', 'facilitate', 'fashion', 'formulate', 'foster', 'generate',
        'grow', 'harness', 'impact', 'implement', 'incentivize', 'incubate', 'initiate', 'innovate', 'integrate', 'iterate',
        'leverage existing', 'leverage other\'s', 'maintain', 'matrix', 'maximize', 'mesh', 'monetize', 'morph', 'myocardinate',
        'negotiate', 'network', 'optimize', 'orchestrate', 'parallel task', 'plagiarize', 'pontificate', 'predominate',
        'procrastinate', 'productivate', 'productize', 'promote', 'provide access to', 'pursue', 'recaptiualize',
        'reconceptualize', 'redefine', 're-engineer', 'reintermediate', 'reinvent', 'repurpose', 'restore', 'revolutionize',
        'scale', 'seize', 'simplify', 'strategize', 'streamline', 'supply', 'syndicate', 'synergize', 'synthesize', 'target',
        'transform', 'transition', 'underwhelm', 'unleash', 'utilize', 'visualize', 'whiteboard', 'cloudify', 'right-shore'
    );

    var adjectives = new Array (
        '24/7', '24/365', 'accurate', 'adaptive', 'alternative', 'an expanded array of', 'B2B', 'B2C', 'backend',
        'backward-compatible', 'best-of-breed', 'bleeding-edge', 'bricks-and-clicks', 'business', 'clicks-and-mortar',
        'client-based', 'client-centered', 'client-centric', 'client-focused', 'collaborative', 'compelling',  'competitive',
        'cooperative', 'corporate', 'cost effective', 'covalent', 'cross functional', 'cross-media', 'cross-platform',
        'cross-unit', 'customer directed', 'customized', 'cutting-edge', 'distinctive', 'distributed', 'diverse', 'dynamic',
        'e-business', 'economically sound', 'effective', 'efficient', 'emerging', 'empowered', 'enabled', 'end-to-end',
        'enterprise', 'enterprise-wide', 'equity invested', 'error-free', 'ethical', 'excellent', 'exceptional', 'extensible',
        'extensive', 'flexible', 'focused', 'frictionless', 'front-end', 'fully researched', 'fully tested', 'functional',
        'functionalized', 'future-proof', 'global', 'go forward', 'goal-oriented', 'granular', 'high standards in',
        'high-payoff', 'high-quality', 'highly efficient', 'holistic', 'impactful', 'inexpensive', 'innovative',
        'installed base', 'integrated', 'interactive', 'interdependent', 'intermandated', 'interoperable', 'intuitive',
        'just in time', 'leading-edge', 'leveraged', 'long-term high-impact', 'low-risk high-yield', 'magnetic',
        'maintainable', 'market positioning', 'market-driven', 'mission-critical', 'multidisciplinary', 'multifunctional',
        'multimedia based', 'next-generation', 'one-to-one', 'open-source', 'optimal', 'orthogonal', 'out-of-the-box',
        'pandemic', 'parallel', 'performance based', 'plug-and-play', 'premier', 'premium', 'principle-centered', 'proactive',
        'process-centric', 'professional', 'progressive', 'prospective', 'quality', 'real-time', 'reliable', 'resource-sucking',
        'resource-maximizing', 'resource-leveling', 'revolutionary', 'robust', 'scalable', 'seamless', 'stand-alone',
        'standardized', 'standards compliant', 'state of the art', 'sticky', 'strategic', 'superior', 'sustainable',
        'synergistic', 'tactical', 'team building', 'team driven', 'technically sound', 'timely', 'top-line', 'transparent',
        'turnkey', 'ubiquitous', 'unique', 'user-centric', 'user friendly', 'value-added', 'vertical', 'viral', 'virtual',
        'visionary', 'web-enabled', 'wireless', 'world-class', 'worldwide', 'fungible', 'cloud-ready', 'elastic', 'hyper-scale',
        'on-demand', 'cloud-based', 'cloud-centric', 'cloudified'
    );

    var nouns = new Array (
        'action items', 'alignments', 'applications', 'architectures', 'bandwidth', 'benefits',
        'best practices', 'catalysts for change', 'channels', 'collaboration and idea-sharing', 'communities', 'content',
        'convergence', 'core competencies', 'customer service', 'data', 'deliverables', 'e-business', 'e-commerce', 'e-markets',
        'e-tailers', 'e-services', 'experiences', 'expertise', 'functionalities', 'growth strategies', 'human capital',
        'ideas', 'imperatives', 'infomediaries', 'information', 'infrastructures', 'initiatives', 'innovation',
        'intellectual capital', 'interfaces', 'internal or "organic" sources', 'leadership', 'leadership skills',
        'manufactured products', 'markets', 'materials', 'meta-services', 'methodologies', 'methods of empowerment', 'metrics',
        'mindshare', 'models', 'networks', 'niches', 'niche markets', 'opportunities', '"outside the box" thinking', 'outsourcing',
        'paradigms', 'partnerships', 'platforms', 'portals', 'potentialities', 'process improvements', 'processes', 'products',
        'quality vectors', 'relationships', 'resources', 'results', 'ROI', 'scenarios', 'schemas', 'services', 'solutions',
        'sources', 'strategic theme areas', 'supply chains', 'synergy', 'systems', 'technologies', 'technology',
        'testing procedures', 'total linkage', 'users', 'value', 'vortals', 'web-readiness', 'web services', 'fungibility',
        'clouds', 'nosql', 'storage', 'virtualization'
    );

    adjectives = randomarray(adjectives);
    nouns = randomarray(nouns);
    adverbs = randomarray(adverbs);
    verbs = randomarray(verbs);

    var x;

    var statement = adverbs[adverbs.length-1];
    adverbs.length -= 1;
    statement = statement + " " + verbs[verbs.length-1];
    verbs.length -= 1;
    statement = statement + " " + adjectives[adjectives.length-1];
    adjectives.length -= 1;
    statement = statement + " " + nouns[nouns.length-1];
    nouns.length -= 1;

    return statement;
}