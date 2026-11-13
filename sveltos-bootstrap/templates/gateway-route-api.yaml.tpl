# Labels every cluster whose GatewayRoute CRD is Established. The GatewayRoute EventTriggers
# select on it, so their EventSources only reach a cluster once the kind exists: sveltos-agent
# caches API discovery, and a watch started before the CRD fails with "no matches for kind"
# until the agent restarts, silently stopping the mirror or the status back-fill.
apiVersion: lib.projectsveltos.io/v1beta1
kind: Classifier
metadata:
  name: {{ printf "%s-gatewayroute-api" .Values.profilePrefix | quote }}
spec:
  classifierLabels:
    - key: bootstrap.projectsveltos.io/gatewayroute-api
      value: "true"
  deployedResourceConstraint:
    resourceSelectors:
      - group: apiextensions.k8s.io
        version: v1
        kind: CustomResourceDefinition
        name: gatewayroutes.kro.run
        evaluate: |
          function evaluate()
            hs = {}
            hs.matching = false
            if obj.status ~= nil and obj.status.conditions ~= nil then
              for _, condition in ipairs(obj.status.conditions) do
                if condition.type == "Established" and condition.status == "True" then
                  hs.matching = true
                end
              end
            end
            return hs
          end
