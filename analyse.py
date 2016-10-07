
import numpy as np
import pandas as pd

from sklearn import metrics, model_selection as ms
from sklearn import linear_model as lm, tree, ensemble

def mae(y_true, y_pred):
    return np.mean(np.abs(np.exp(y_true) - np.exp(y_pred)))

mae = metrics.make_scorer(mae, greater_is_better=False)

def mape(y_true, y_pred):
    return np.mean(np.abs(np.exp(y_true) - np.exp(y_pred)) / np.exp(y_true))

mape = metrics.make_scorer(mape, greater_is_better=False)

ultrasound = pd.read_csv('datasets/scans.csv')

ultrasound.dropna(
    subset=['parity', 'pregnancies'],
    inplace=True
)

ultrasound['first_pregnancy'] = ultrasound['first_pregnancy'].astype(int)

ultrasound = pd.concat([
    ultrasound,
    pd.get_dummies(ultrasound.study_id, prefix='study', drop_first=True),
    pd.get_dummies(ultrasound.sex, prefix='sex').drop('sex_M', axis=1),
    pd.get_dummies(ultrasound.parity_cat, prefix='parity', drop_first=True),
], axis=1)

X = pd.concat([
    ultrasound.ix[:,'ac_1':'gage_3_missing'],
    ultrasound[[
        'sex_F',
        'parity_1', 'parity_2', 'parity_3+',
        'first_pregnancy'
    ]]
], axis=1)

y = np.log(ultrasound['ft_wt'])

kf = ms.KFold(10, shuffle=True, random_state=1)

model_lr = lm.LinearRegression()
model_lr.fit(X, y)
print('Linear Regression MAE: {}'.format(-np.mean(ms.cross_val_score(model_lr, X, y, scoring=mae))))
print('Linear Regression MAPE: {}'.format(-np.mean(ms.cross_val_score(model_lr, X, y, scoring=mape))))

gs_enet = ms.GridSearchCV(
    estimator=lm.ElasticNet(),
    param_grid={
        'alpha': [0.0001, 0.001, 0.01, 0.1, 1, 10, 100, 1000],
        'l1_ratio': [0.0, 0.1, 0.5, 0.7, 0.9, 0.95, 0.99, 1.0]
    },
    scoring=mape,
    cv=kf
)
gs_enet.fit(X, y)
print('Elastic Net MAPE: {}'.format(-gs_enet.best_score_))

gs_enet = ms.GridSearchCV(
    estimator=lm.ElasticNet(),
    param_grid={
        'alpha': [0.0001, 0.001, 0.01, 0.1, 1, 10, 100, 1000],
        'l1_ratio': [0.0, 0.1, 0.5, 0.7, 0.9, 0.95, 0.99, 1.0]
    },
    scoring=mape,
    cv=kf
)
gs_enet.fit(X, y)
print('Elastic Net MAE: {}'.format(-gs_enet.best_score_))

model_dt = ensemble.AdaBoostRegressor(
    base_estimator=tree.DecisionTreeRegressor(min_samples_leaf=0.01),
    n_estimators=500
)
model_dt.fit(X, y)
print('Tree + AdaBoost: {}'.format(-np.mean(ms.cross_val_score(model_dt, X, y, scoring=mape))))

gs_rf = ms.GridSearchCV(
    estimator=ensemble.RandomForestRegressor(),
    param_grid={
        'n_estimators': [1, 2, 5, 10, 20, 50, 100]
    },
    scoring=mape,
    cv=kf
)
gs_rf.fit(X, y)
print('Random Forest: {}'.format(-gs_rf.best_score_))

