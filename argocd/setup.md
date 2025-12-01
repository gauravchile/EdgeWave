# 🧠 Argo CD Setup via Dashboard (for EdgeWave)

This guide assumes your EKS cluster and Argo CD have already been installed using:

```bash
make cluster-bootstrap
```

---

## 1️⃣ Port-forward Argo CD UI

```bash
kubectl -n argocd port-forward svc/argocd-server 8090:80
```

Now open your browser and visit:
👉 [http://localhost:8090](http://localhost:8090)

---

## 2️⃣ Retrieve Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

Use these credentials:

```
Username: admin
Password: <output_from_above>
```

---

## 3️⃣ Create the EdgeWave Application

In the Argo CD dashboard:

Click **NEW APP** → fill out the form exactly like this 👇

| Field                | Value                                                                                      |
| -------------------- | ------------------------------------------------------------------------------------------ |
| **Application Name** | edgewave                                                                                   |
| **Project**          | default                                                                                    |
| **Sync Policy**      | Automatic (✔ Self-Heal, ✔ Prune)                                                           |
| **Repository URL**   | [https://github.com/gauravchile/edgewave.git](https://github.com/gauravchile/edgewave.git) |
| **Revision**         | main                                                                                       |
| **Path**             | manifests/overlays/prod                                                                    |
| **Cluster URL**      | [https://kubernetes.default.svc](https://kubernetes.default.svc)                           |
| **Namespace**        | edgewave                                                                                   |

Click **Create**.

✅ Argo CD will now automatically sync your deployments whenever Jenkins updates the manifests in GitHub.

---

## 4️⃣ Verify Sync

After Jenkins completes a pipeline run (build → push → commit), check Argo CD UI:

* App status should show **Synced** ✅
* Pods in EKS should update to new image tags.

Run:

```bash
kubectl -n edgewave get pods -o wide
```

---

## 5️⃣ (Optional) Enable Email Notifications

In Argo CD UI → ⚙️ **Settings → Notifications → Add Service → Email**

| Field       | Example                                                           |
| ----------- | ----------------------------------------------------------------- |
| SMTP Server | smtp.gmail.com                                                    |
| Port        | 587                                                               |
| Username    | [your.email@gmail.com](mailto:your.email@gmail.com)               |
| Password    | app password (from Google)                                        |
| Sender      | EdgeWave CD [no-reply@edgewave.dev](mailto:no-reply@edgewave.dev) |

Then under **Subscriptions**, add these triggers:

```
on-sync-succeeded
on-sync-failed
on-health-degraded
```

Recipient → your Gmail or team distribution list.

---

## 6️⃣ Verify End-to-End Flow

1️⃣ Run Jenkins pipeline → commits manifests → GitHub updated.
2️⃣ Argo CD auto-syncs → deploys new version.
3️⃣ Check service:

```bash
kubectl -n edgewave get svc edgewave-frontend -o wide
```

4️⃣ Visit LoadBalancer IP → see Blue/Green frontend color.

✅ EdgeWave is now fully GitOps-driven!
