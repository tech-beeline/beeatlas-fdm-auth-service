/*
 * Copyright (c) 2024 PJSC VimpelCom
 */

package ru.beeline.fdmauth.controller.rbac;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.domain.rbac.CheckType;
import ru.beeline.fdmauth.dto.rbac.PolicyConflictDTO;
import ru.beeline.fdmauth.dto.rbac.PolicyFullDTO;
import ru.beeline.fdmauth.service.rbac.RbacAdminService;

import java.util.List;

@RestController
@RequestMapping("/api/admin/v1/rbac")
public class RbacController {

    @Autowired
    private RbacAdminService rbacAdminService;

    @GetMapping(value = "/policy", produces = "application/json")
    public ResponseEntity<List<PolicyFullDTO>> getAllPolicies() {
        return ResponseEntity.ok(rbacAdminService.getAllPolicies());
    }

    @GetMapping(value = "/policy/{id}", produces = "application/json")
    public ResponseEntity<PolicyFullDTO> getPolicy(@PathVariable Long id) {
        return ResponseEntity.ok(rbacAdminService.getPolicy(id));
    }

    @PostMapping(value = "/policy", produces = "application/json")
    public ResponseEntity<PolicyFullDTO> createPolicy(@RequestBody PolicyFullDTO dto) {
        return ResponseEntity.ok(rbacAdminService.createPolicy(dto));
    }

    @PutMapping(value = "/policy/{id}", produces = "application/json")
    public ResponseEntity<PolicyFullDTO> updatePolicy(@PathVariable Long id, @RequestBody PolicyFullDTO dto) {
        return ResponseEntity.ok(rbacAdminService.updatePolicy(id, dto));
    }

    @DeleteMapping(value = "/policy/{id}")
    public ResponseEntity<Void> deletePolicy(@PathVariable Long id) {
        rbacAdminService.deletePolicy(id);
        return ResponseEntity.ok().build();
    }

    @GetMapping(value = "/check-type", produces = "application/json")
    public ResponseEntity<List<CheckType>> getAllCheckTypes() {
        return ResponseEntity.ok(rbacAdminService.getAllCheckTypes());
    }

    @GetMapping(value = "/export", produces = "application/json")
    public ResponseEntity<List<PolicyFullDTO>> exportPolicies() {
        return ResponseEntity.ok(rbacAdminService.exportPolicies());
    }

    @PostMapping(value = "/import", produces = "application/json")
    public ResponseEntity<?> importPolicies(@RequestBody List<PolicyFullDTO> policies,
                                            @RequestParam(defaultValue = "false") boolean reWrite) {
        List<PolicyConflictDTO> conflicts = rbacAdminService.importPolicies(policies, reWrite);
        if (!conflicts.isEmpty()) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(conflicts);
        }
        return ResponseEntity.ok().build();
    }
}
