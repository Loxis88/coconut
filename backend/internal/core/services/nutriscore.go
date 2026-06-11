package services

import "github.com/coconut/backend/internal/core/domain"

// Nutri-Score algorithm ported from data/dds/calc_nutriscore_kuper.py.
// Returns a 0-100 rating (higher = healthier), nil if calories unavailable.

var (
	energyKJTable = [][2]float64{{335, 0}, {670, 1}, {1005, 2}, {1340, 3}, {1675, 4}, {2010, 5}, {2345, 6}, {2680, 7}, {3015, 8}, {3350, 9}}
	satFatTable   = [][2]float64{{1, 0}, {2, 1}, {3, 2}, {4, 3}, {5, 4}, {6, 5}, {7, 6}, {8, 7}, {9, 8}, {10, 9}}
	sugarsTable   = [][2]float64{{4.5, 0}, {9, 1}, {13.5, 2}, {18, 3}, {22.5, 4}, {27, 5}, {31, 6}, {36, 7}, {40, 8}, {45, 9}}
	sodiumMgTable = [][2]float64{{90, 0}, {180, 1}, {270, 2}, {360, 3}, {450, 4}, {540, 5}, {630, 6}, {720, 7}, {810, 8}, {900, 9}}
	fiberTable    = [][2]float64{{0.9, 0}, {1.9, 1}, {2.8, 2}, {3.7, 3}, {4.7, 4}}
	proteinTable  = [][2]float64{{1.6, 0}, {3.2, 1}, {4.8, 2}, {6.4, 3}, {8.0, 4}}
)

const (
	scoreMin = -10
	scoreMax = 40
)

func nutriLookup(value *float64, table [][2]float64) int {
	if value == nil {
		return 0
	}
	for _, row := range table {
		if *value <= row[0] {
			return int(row[1])
		}
	}
	return len(table)
}

func calcNutriScore(nf *domain.NutritionFacts) *float64 {
	if nf == nil || nf.CaloriesKcal == nil {
		return nil
	}
	energyKJ := *nf.CaloriesKcal * 4.184

	var sodiumMg *float64
	if nf.SodiumMg != nil {
		sodiumMg = nf.SodiumMg
	} else if nf.SaltG != nil {
		v := *nf.SaltG * 400.0
		sodiumMg = &v
	}

	n := nutriLookup(&energyKJ, energyKJTable) +
		nutriLookup(nil, satFatTable) + // saturated fat enriched separately by Python pipeline
		nutriLookup(nf.SugarG, sugarsTable) +
		nutriLookup(sodiumMg, sodiumMgTable)
	p := nutriLookup(nf.FiberG, fiberTable) + nutriLookup(nf.ProteinG, proteinTable)

	score := n - p
	if score < scoreMin {
		score = scoreMin
	}
	if score > scoreMax {
		score = scoreMax
	}
	rating := float64(scoreMax-score) / float64(scoreMax-scoreMin) * 100
	return &rating
}
