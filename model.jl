using Pkg
Pkg.activate(".")
using Agents
using Random
using Distributions
using Statistics
using Plots

# Ziel: 
# Es sollen mehrere Schedulung-Strategien verglichen werden:
# Chronologisch, 100% Kistra (PL > NL), 50% Kistra 50% Alter, 33% Kistra 33% Alter 33% Random.
# Forschungsfragen: 
# Bei welcher Strategie bleiben die wenigsten false negatives unbearbeitet?
# Bei welcher Strategie wird Hatespeech am schnellsten abgearbeitet? 

Base.@kwdef mutable struct Post
    id::Int = 0
    timestamp::Int = 1 # Spielrunde, bei der der Post abgesetzt wurde.
    opinion::Float64 = 0 # -1 bis 1
    is_hate::Bool = false # ground truth. Handelt es sich um Hatespeech?
    reports::Int = 0 # Anzahl, wie oft der Beitrag gemeldet wurde.
end

# Konstanten für unsere Simulation
const max_days = 31
const post_per_day = 10000 

rng = Xoshiro(99)

# Unsere Verteilungen
opinion_dist = Uniform(-1,1)
hate_dist = Bernoulli(0.05) # 10 Prozent ist hate
reporting_dist_non_hate = Exponential(0.5) # wenige Meldungen 
reporting_dist_hate = Exponential(1.5)

# Realistische Annahmen wären:
# - Report: 50% ein mal gemeldet, 50% mindestens zwei mal. Maximum ist 20-30.
# - Beziehung zwischen opinion und reporting ist noch unklar. Ergebnisse LMU Umfrage?
# - 10000 bis 20000 Meldungen pro Monat. Bei Events wird verdoppelt.
# - 20 bis 30% der gemeldeten Beiträge sind wirklich relevant. 

# Test für unsere reporting distribution
using Plots
test = [floor(rand(rng,reporting_dist_hate)) for x in 1:1000]
histogram(test)

# Generiere die Posts
liste = Vector{Post}()
id_count = 0
for day in 1:max_days
    for i in 1:post_per_day
        global id_count = id_count + 1
        is_h = rand(rng, hate_dist)
        tmp = Post( id = id_count, 
                    timestamp = day, 
                    opinion = rand(rng, opinion_dist), 
                    is_hate = is_h,
                    reports = is_h ? 
                            convert(Int, floor(rand(rng, reporting_dist_hate))) : 
                            convert(Int, floor(rand(rng, reporting_dist_non_hate))))
        push!(liste, tmp)
    end 
end

# Helferfunktionen zum Erkennen
function isTPreport(p::Post)
    p.is_hate && p.reports > 0 # Korrekt. Beitrag ist Hass. Beitrag ist mindestens 1 mal gemeldet worden. 
end

function isTNreport(p::Post)
    !p.is_hate && p.reports == 0 # Korrekt. Beitrag ist kein Hass. Beitrag ist 0 mal gemeldet worden. 
end

function isFPreport(p::Post)
    !p.is_hate && p.reports > 0 # Alphafehler. Beitrag ist kein Hass. Beitrag ist mindestens 1 mal gemeldet worden.  
end

function isFNreport(p::Post)
    p.is_hate && p.reports == 0 # Betafehler. Beitrag ist Hass. Beitrag ist 0 mal gemeldet worden. 
end

liste

report_conf_matrix = zeros(Int, 2, 2)


# Reporting Matrix berechnen
# Wichtig: Dies ist für die Konfusionsmatrix der Mitglieder des sozialen Netzwerks.
for i in 1:length(liste)
    if isTPreport(liste[i])
        report_conf_matrix[1,1] += 1
    end
    if isTNreport(liste[i])
        report_conf_matrix[2,2] += 1
    end
    if isFPreport(liste[i])
        report_conf_matrix[1,2] += 1
    end
    if isFNreport(liste[i])
        report_conf_matrix[2,1] += 1
    end
end

report_conf_matrix#

# Klassifier
# Perfekter Klassifizierer:
perfect_conf_matrix = [[1,0.0]  [0.0,1.0] ] 
# Ungefährer Kistra Klassifizierer für §130.
kistra_conf_matrix = [[0.7,0.3]  [0.1,0.9] ]



function classify(conf_matrix::Matrix{Float64}, p::Post, rng::AbstractRNG)
    probability = 0.0
    if p.is_hate 
        #println("Ishate")
        probability = conf_matrix[1,1]
    else
        #println("Is non hate")
        probability = conf_matrix[2,2]
    end

    guess = rand(rng, Bernoulli(probability)) # = liegt der Klassifikator richtig?

    if guess 
        p.is_hate # p.is_hate wird unverändert zurückgegeben: TP oder TN.
    else
        !p.is_hate # p.is_hate wird invertiert zurückgegeben: FP oder FN.
    end
end



#classify(perfect_conf_matrix,Post(is_hate = true),rng)


ki_conf_matrix = zeros(Int, 2, 2)
for i in 1:length(liste)
    if liste[i].reports > 0
        cls_result = classify(kistra_conf_matrix, liste[i], rng)
        # hass korrekt gefunden
        if liste[i].is_hate && cls_result
            ki_conf_matrix[1,1] += 1
        end
        # hass inkorrekt gefunden
        if (!liste[i].is_hate) && cls_result
            ki_conf_matrix[1,2] += 1
        end
        # keinhass korrekt gefunden
        if (!liste[i].is_hate) && !cls_result
            ki_conf_matrix[2,2] += 1
        end
        # keinhass inkorrekt gefunden
        if (liste[i].is_hate) && !cls_result
            ki_conf_matrix[2,1] += 1
        end
    end
end

ki_conf_matrix


# TODOS:
# Komponente virtuelles BKA. Fehlerfreie Abarbeitung von 400-500 Beiträgen pro Tag.
# Scheduling Strategien: Chronologisch, 100% Kistra (PL > NL), 50% Kistra 50% Alter, 33% Kistra 33% Alter 33% Random.
# Diskussionspukt: Wie werden die Mehrfachmeldungen in den Sortierungen berücksichtigt? 
# Zielgrößen: 
#   - Anzahl unbearbeiteter FN im Zeitverlauf. 
#   - Durchschnittliche Wartezeit von Hass bis zur Bearbeitung.
# "Gute" und "schlechte" Events. 
#   - Gutes Event: Anzahl der Meldungen verdoppelt sich, Verteilung bleibt gleich. z.B. Festplattenübergabe durch Dritte.
#   - Schlechtes Event: Anzahl der Meldungen verdoppelt sich, es steigen aber nur die false positives. 
#       z.B. Ermordung eines Polizisten führt dazu, dass Beiträge mit inhaltlichem Bezug von Nutzern gemeldet werden, obwohl das gar kein Hass ist. 

# Diskussionspunkte mit LMU:
# Hypothese Julian: Rechts postet mehr Hass, Links meldet mehr?
# Ergebnisse Ursula Folie 24: Nutzer beschäftigen sich mit Hatespeech, wenn sie persönlich betroffen sind oder der Post sie entsetzt. 
#   - Indikator 1: Entsetzen und Sorge. Operationalisierung über Distanz zur eigenen Meinung?
#   - Indikator 2: Pers. Betroffenheit. Operationalisierung über Hate + Verbindung? 